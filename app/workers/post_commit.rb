#require 'faye'
class PostCommit
  include PoiHelper

  # queue for resque
  @queue = :post_commit

  # callback for resque-worker
  def self.perform *args
    args_hash = args.first
    case args_hash['action']
      when 'sync_pois'
        PostCommit.sync_pois args_hash['user_id'], args_hash['poi_ids'], args_hash['min_local_time_secs_list']
      when 'delete_poi'
        PostCommit.delete_poi args_hash['user_id'], args_hash['poi_id']
      when 'pull_pois'
        PostCommit.pull_pois args_hash['user_id'], args_hash['commit_hash']
    end
  end

  def self.pull_pois user_id, commit_hash
    PostCommit.new.pull_pois user_id, commit_hash
  end

  #
  # read only - for write/commit @see sync_pois
  #
  def pull_pois user_id, commit_hash, fork_publish = true
    @user = User.find user_id

    vm = VersionManager.new Poi::MASTER, Poi::WORK_DIR_ROOT, @user, false#@user.is_admin?
    prev_commit = vm.cur_commit

    # Commit.latest.hash_id

    if prev_commit != commit_hash
#binding.pry if Rails.env.to_sym == :development
      vm.forward commit_hash
      prev_commit = commit_hash
    end
    
    @new_pois = []
    @modified_pois = []
    @deleted_pois = []

    diff = vm.changed
    # TODO - for now only add is implemented.
    diff_added = diff['A']
    diff_modified = diff['M']
    diff_deleted = diff['D']
    if diff_added.present?
#binding.pry if Rails.env.to_sym == :development
      # entries are sorted by poi. every time the (list)poi changes, a new poi is started
      poi_ids = []
      pois = {}
      diff_added.each do |entry|
        note_match = entry.match(/^location_([0-9]+)/)
        next if note_match.present?
        note_match = entry.match(/^note_([0-9]+)/)
        unless note_match.present?
          poi_match = entry.match(/^poi_([0-9]+)/)
#binding.pry if Rails.env.to_sym == :development
          poi_ids << poi_match[1].to_i
          next
        end
        poi_note = PoiNote.where(id: note_match[1].to_i).first
        if poi_note.present?
          cur_poi_note_jsons = pois[poi_note.poi.id]
          same_poi = cur_poi_note_jsons.present?
          unless same_poi
            cur_poi_note_jsons = []
            pois[poi_note.poi.id] = cur_poi_note_jsons
          end
          cur_poi_note_jsons << poi_note_json(poi_note, !same_poi)
        else
          Rails.logger.warn "poi_note[id=#{note_match[1]}] found in diff from user/branch #{@user.id}/#{vm.cur_branch} but not in db"
        end
      end
      pois.each do |poi_id, poi_notes|
        if poi_ids.include? poi_id
          @new_pois << poi_notes
        else
          @modified_pois << poi_notes
        end 
      end
    end
    
    #Commit.latest.hash_id
    vm.fast_forward
    cur_commit = vm.cur_commit

    system_msg_for_user = { type: 'callback',
                            channel: 'pois',
                            action: 'pull',
                            commit_hash: cur_commit,
                            new_pois: @new_pois,
                            modified_pois: @modified_pois,
                            deleted_pois: @deleted_pois }

    msgs_data = [
                  { channel: "/system#{PEER_CHANNEL_PREFIX}#{@user.comm_port.sys_channel_enc_key}",
                    msg: system_msg_for_user,
                    user_id: @user.id }
                ]
    Publisher.new.publish msgs_data, fork_publish
  end

  # updates the users repository:
  # 1) pulls data meanwhile created by other users 
  # 2) pushes data created by this user (vm)
  def self.sync_pois user_id, poi_ids, min_local_time_secs_list
    PostCommit.new.sync_pois user_id, poi_ids, min_local_time_secs_list
  end

  def sync_pois user_id, poi_ids, min_local_time_secs_list, fork_publish = true
    @user = User.find user_id

    vm = VersionManager.new Poi::MASTER, Poi::WORK_DIR_ROOT, @user, false#@user.is_admin?
    prev_commit = vm.cur_commit
    diff = vm.changed
    # TODO - for now only add is implemented.
    diff_added = diff['A']
    diff_modified = diff['M']
    diff_deleted = diff['D']
#  binding.pry    
    @poi_jsons_for_user = []
    @poi_jsons_for_others = []
    min_local_time_secs = -1
    sync_infos = {}
    poi_ids.each_with_index do |poi_id, idx|
      if poi_id.to_i >= 0
        poi = Poi.find poi_id
      else
        poi = Poi.joins(:notes).where(poi_notes: {user_id: @user.id}, local_time_secs: min_local_time_secs_list[idx]).first
      end
      is_new_poi = poi.commit_hash.nil?
      is_new_location = poi.location.commit_hash.nil?

      added_user_notes = []

      vm.add_poi poi
      # add new pois from user
      poi.notes.each do |note|
        next unless note.user_id == @user.id && note.local_time_secs >= min_local_time_secs_list[idx]
        added_user_notes << note
        vm.add_poi_note poi, note
      end
      sync_infos[poi_id] = { poi: poi, is_new_poi: is_new_poi, is_new_location: is_new_location, added_user_notes: added_user_notes }
      min_local_time_secs = min_local_time_secs_list[idx] if min_local_time_secs_list[idx]<min_local_time_secs || min_local_time_secs==-1
    end
    
    vm.merge true, true
    cur_commit = vm.cur_commit
    commit = @user.commits.create hash_id: cur_commit, timestamp: DateTime.now, local_time_secs: min_local_time_secs
    @user.snapshot.update_attribute :cur_commit, commit

    poi_ids.each_with_index do |poi_id, idx|
      poi = sync_infos[poi_id][:poi]
      poi.location.update_attribute(:commit_hash, cur_commit) if sync_infos[poi_id][:is_new_location]
      poi.update_attribute(:commit_hash, cur_commit) if sync_infos[poi_id][:is_new_poi]

      note_json_list_for_user = [] # added to upload-message for user
      note_json_list_for_others = [] # added to upload-message for others

      #added_user_notes.each do |note|
      sync_infos[poi_id][:added_user_notes].each do |note|
        note.update_attribute :commit_hash, cur_commit
        # show local_time_secs only to @user
        note_json_for_others = poi_note_json note, false
        note_json_list_for_others << note_json_for_others
        note_json_list_for_user << note_json_for_others.
                                   merge({local_time_secs: note.local_time_secs})
      end

      # prepend all entries changed by remote users while local user was offline
      # TODO - find merge-algorithm for new notes added by others and by user
      #        this could be implemented on the client side as well. (lovely bags)
      if diff_added.present?
        diff_added.each do |entry|
          # this part is done by  pulled befors sync and not handled here
          # poi_match = entry.match(/^poi_([0-9]+)/)
          # if poi_match.present?
          #   # complete poi (including notes) added by remote users while local user was offline
          #   new_poi = Poi.find(poi_match[1].to_i)
          #   new_poi_json = poi_json new_poi
          #   new_note_json_list
          #   new_poi.notes.each do |note|
          #     new_note_json_list << poi_note_json note, false
          #   end
          #   @poi_jsons_for_user << new_poi_json.merge!({notes: new_note_json_list})
          #   next
          # end
          note_match = entry.match(/^note_([0-9]+)/)
          next unless note_match.present?
          poi_note = PoiNote.where(id: note_match[1].to_i).first
          if poi_note.present?
            if poi_note.poi == poi
              note_json_list_for_user.unshift poi_note_json(poi_note)
            end
          else
            Rails.logger.warn "poi_note[id=#{note_match[1]}] found in diff from user/branch #{@user.id}/#{vm.cur_branch} but not in db"
          end
        end
      end

      poi_json = poi_json(poi).merge({user: { id: @user.id }})
      # old sync per poi: poi_json_for_others = poi_json
      poi_json_for_others = { poi_id: poi.id, lat: poi.location.latitude, lng: poi.location.longitude }
      poi_json_for_user = poi_json.
                          merge(sync_infos[poi_id][:is_new_poi] ? {local_time_secs: poi.local_time_secs} : {})
      # old sync per poi: poi_json_for_others.merge!({notes: note_json_list_for_others})
      poi_json_for_user.merge!({notes: note_json_list_for_user})

      @poi_jsons_for_user << poi_json_for_user
      @poi_jsons_for_others << poi_json_for_others
    end
    
    system_msg_for_user = { type: 'callback',
                            channel: 'pois',
                            action: 'poi_sync',
                            commit_hash: commit.hash_id,
                            pois: @poi_jsons_for_user }
    upload_msg_for_others = { type: 'pull_request',
                              commit_hash: commit.hash_id,
                              push_user_id: @user.id,
                              pois: @poi_jsons_for_others }

    msgs_data = [
                  { channel: "/system#{PEER_CHANNEL_PREFIX}#{@user.comm_port.sys_channel_enc_key}",
                    msg: system_msg_for_user,
                    user_id: @user.id },
                 #{ channel: "/pois#{PEER_CHANNEL_PREFIX}#{@user.comm_port.channel_enc_key}",
                  { channel: "/system",
                    msg: upload_msg_for_others,
                    user_id: @user.id }
                ]
    Publisher.new.publish msgs_data, fork_publish
  end

  # updates the users repository:
  # 1) pulls data meanwhile created by other users 
  # 2) pushes data created by this user (vm)
  def self.delete_poi user_id, poi_id
    PostCommit.new.delete_poi user_id, poi_id
  end

  def delete_poi user_id, poi_id, fork_publish = true
    @user = User.find user_id

    vm = VersionManager.new Poi::MASTER, Poi::WORK_DIR_ROOT, @user, false#@user.is_admin?
    prev_commit = vm.cur_commit
    
    vm.delete_poi poi_id

    vm.merge true, true
    cur_commit = vm.cur_commit
   
    system_msg_for_user = { type: 'callback',
                            channel: 'pois',
                            action: 'poi_delete',
                            commit_hash: cur_commit,
                            poi_id: poi_id }
    upload_msg_for_others = { type: 'poi_delete',
                              commit_hash: cur_commit,
                              poi_id: poi_id }

   msgs_data = [
                  { channel: "/system#{PEER_CHANNEL_PREFIX}#{@user.comm_port.sys_channel_enc_key}",
                    msg: system_msg_for_user,
                    user_id: @user.id },
                 #{ channel: "/pois#{PEER_CHANNEL_PREFIX}#{@user.comm_port.channel_enc_key}",
                  { channel: "/system",
                    msg: upload_msg_for_others,
                    user_id: @user.id }
                ]
    Publisher.new.publish msgs_data, fork_publish
  end

end
