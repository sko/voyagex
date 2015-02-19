#require 'faye'
class PostCommit
  include PoiHelper
  
  FAYE_CLIENT = Faye::Client.new(::FAYE_URL)

  # queue for resque
  @queue = :post_commit

  # callback for resque-worker
  def self.perform *args
    args_hash = args.first
    case args_hash['action']
      when 'sync_poi'
        PostCommit.sync_poi args_hash['user_id'], args_hash['poi_id'], args_hash['min_local_time_secs']
    end
  end

  # updates the users repository:
  # 1) pulls data meanwhile created by other users 
  # 2) pushes data created by this user (vm)
  def self.sync_poi user_id, poi_id, min_local_time_secs
    PostCommit.new.sync_poi user_id, poi_id, min_local_time_secs
  end

  def sync_poi user_id, poi_id, min_local_time_secs
    @user = User.find user_id
    @poi = Poi.find poi_id
    is_new_poi = @poi.commit_hash.nil?
    is_new_location = @poi.location.commit_hash.nil?

    added_user_notes = []
    note_json_list_for_user = [] # added to upload-message for user
    note_json_list_for_others = [] # added to upload-message for others

    vm = VersionManager.new UploadsController::MASTER, UploadsController::WORK_DIR_ROOT, @user, false#@user.is_admin
    prev_commit = vm.cur_commit
    diff = vm.changed
    # TODO - for now only add is implemented.
    diff_added = diff['A']
    diff_modified = diff['M']
    diff_deleted = diff['D']
    
    vm.add_poi @poi
    # add new pois from user
    @poi.notes.each do |note|
      next unless note.user_id == @user.id && note.local_time_secs >= min_local_time_secs
      added_user_notes << note
      vm.add_poi_note @poi, note
    end

    vm.merge true, true
    cur_commit = vm.cur_commit
    
    @poi.location.update_attribute(:commit_hash, cur_commit) if is_new_location
    @poi.update_attribute(:commit_hash, cur_commit) if is_new_poi
    added_user_notes.each do |note|
      note.update_attribute :commit_hash, cur_commit
      # show local_time_secs only to @user
      note_json_for_others = poi_note_json note, false
      note_json_list_for_others << note_json_for_others
      note_json_list_for_user << note_json_for_others.
                                 merge({local_time_secs: note.local_time_secs})
    end
    commit = @user.commits.create hash_id: cur_commit, timestamp: DateTime.now, local_time_secs: added_user_notes.first.local_time_secs
    @user.snapshot.update_attribute :cur_commit, commit

    # TODO - find merge-algorithm for new notes added by others and by user
    #        this could be implemented on the client side as well. (lovely bags)
    if diff_added.present?
      diff_added.each do |entry|
        note_match = entry.match(/^note_([0-9]+)/)
        next unless note_match.present?
        poi_note = PoiNote.where(note_match[1].to_i).first
        if poi_note.present?
          if poi_note.poi == @poi
            note_json_list_for_user.unshift poi_note_json(poi_note)
          end
        else
          Rails.logger.warn "poi_note[id=#{note_match[1]}] found in diff from user/branch #{@user.id}/#{vm.cur_branch} but not in db"
        end
      end
    end

    @poi_json_for_others = poi_json(@poi).merge({user: { id: @user.id }})
    @poi_json_for_user = @poi_json_for_others.
                         merge(is_new_poi ? {local_time_secs: @poi.local_time_secs} : {})
    @poi_json_for_others.merge!({notes: note_json_list_for_others})
    @poi_json_for_user.merge!({notes: note_json_list_for_user})
    
    system_msg_for_user = { type: 'callback',
                            channel: 'uploads',
                            action: 'poi_sync',
                            commit_hash: cur_commit,
                            poi: @poi_json_for_user }
    upload_msg_for_others = { type: 'poi_sync',
                              commit_hash: cur_commit,
                              poi: @poi_json_for_others }

    EM.run {
      num_cbs = 0

      channel_path = '/system'
      channel_path += "#{PEER_CHANNEL_PREFIX}#{@user.comm_setting.sys_channel_enc_key}" unless USE_GLOBAL_SUBSCRIBE
      publication_1 = PostCommit::FAYE_CLIENT.publish(channel_path, system_msg_for_user)
      publication_1.callback { Rails.logger.debug("sent poi-sync-msg to user: commit_hash = #{cur_commit}"); EM.stop if (num_cbs += 1) == 2 }
      publication_1.errback {|error| Rails.logger.error("poi-sync-msg to user: commit_hash = #{cur_commit} - error: #{error.message}"); EM.stop if (num_cbs += 1) == 2 }

      channel_path = '/uploads'
      channel_path += "#{PEER_CHANNEL_PREFIX}#{@user.comm_setting.channel_enc_key}" unless USE_GLOBAL_SUBSCRIBE
      publication_2 = PostCommit::FAYE_CLIENT.publish(channel_path, upload_msg_for_others)
      publication_2.callback { Rails.logger.debug("sent poi-sync-msg to others: commit_hash = #{cur_commit}"); EM.stop if (num_cbs += 1) == 2 }
      publication_2.errback {|error| Rails.logger.error("poi-sync-msg to others: commit_hash = #{cur_commit} - error: #{error.message}"); EM.stop if (num_cbs += 1) == 2 }
    }
  end

end
