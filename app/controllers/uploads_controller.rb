class UploadsController < ApplicationController 
  include GeoUtils
  include ApplicationHelper
  include PoiHelper

  skip_before_filter :verify_authenticity_token, only: [:create, :update]
  
  MASTER = 'test/master'
  WORK_DIR_ROOT = "#{Rails.root}/user_repos"

  def index
    render layout: 'uploads'
  end

  #
  # TODO: 
  # +) comment-on
  #
  # sync pois that where edited offline
  def sync_poi
    @user = current_user || tmp_user
    if params[:id].present?
      @commented_poi_note = PoiNote.find(params[:id])
      @poi = @commented_poi_note.poi
      # if poi is deleted then create new one - tell user to replace old ...
    else
      @poi = nearby_poi @user, Location.new(latitude: params[:location][:latitude], longitude: params[:location][:longitude])
    end
    @user.locations << @poi.location unless @user.locations.find {|l|l.id==@poi.location.id}
    is_new_poi = @poi.notes.empty?

    # TODO: decide on merge-order-algorithm
    # TODO: only notes for given poi are added - all other changes must be sent to client after_sync
    min_local_time_secs = -1
    params[:poi_note_ids].each do |poi_note_id|
      poi_note_local_time_secs = poi_note_id.to_i.abs # (poi_note_id.to_i/1000).round.abs
      min_local_time_secs = poi_note_local_time_secs if (min_local_time_secs == -1) || (poi_note_local_time_secs < min_local_time_secs)

      file = params[:poi_note][poi_note_id][:file]
      if file.present? || (embed = params[:poi_note][poi_note_id][:embed]).present?
        upload = Upload.new(attached_to: PoiNote.new(poi: @poi, user: @user, text: params[:poi_note][poi_note_id][:text], local_time_secs: poi_note_local_time_secs))
        upload.attached_to.attachment = upload
        if file.present?
          upload.build_entity file.content_type, file: file
        else
          upload.build_entity :embed, text: embed[:content], embed_type: UploadEntity::Embed.get_embed_type(embed[:content])
        end
        poi_note = upload.attached_to
      else
        poi_note = PoiNote.new(poi: @poi, user: @user, text: params[:poi_note][poi_note_id][:text], local_time_secs: poi_note_local_time_secs)
      end
      @poi.notes << poi_note
    end
    @poi.local_time_secs = min_local_time_secs if is_new_poi

    if @poi.save
#      Resque.enqueue(PostSync, {action: 'sync_poi',
#                                user_id: @user.id,
#                                poi_id: @poi.id,
#                                min_local_time_secs: min_local_time_secs})
      PostCommit.new.sync_poi @user.id,
                              @poi.id,
                              min_local_time_secs

      render json: { message: 'OK' }
    else
      render json: { errors: @poi.errors.full_messages }, status: 401
    end
  end

  #
  # TODO: 
  # +) comment-on
  #
  # sync pois that where edited offline
  def sync_poi_no_resque
    @user = current_user || tmp_user
    # vm
    vm = VersionManager.new UploadsController::MASTER, UploadsController::WORK_DIR_ROOT, @user, false#@user.is_admin
    prev_commit = vm.cur_commit
    diff = vm.changed
    # TODO
    # for now only add is implemented.
    diff_added = diff['A']
    diff_modified = diff['M']
    diff_deleted = diff['D']
    
    if params[:id].present?
      @commented_poi_note = PoiNote.find(params[:id])
      @poi = @commented_poi_note.poi
      # if poi is deleted then create new one - tell user to replace old ...
    else
      @poi = nearby_poi @user, Location.new(latitude: params[:location][:latitude], longitude: params[:location][:longitude])
      # vm
      vm.add_location @poi.location
    end
    @user.locations << @poi.location unless @user.locations.find {|l|l.id==@poi.location.id}
    is_new_poi =  @poi.notes.empty?

    # TODO: decide on merge-order-algorithm
    # TODO: only notes for given poi are added - all other changes must be sent to client after_sync
    new_poi_notes = []
    poi_note_json_list = []
    if diff_added.present?
      diff_added.each do |entry|
        note_match = entry.match(/^note_([0-9]+)/)
binding.pry
        next unless note_match.present?
        poi_note = PoiNote.where(note_match[1].to_i).first
        if poi_note.present?
          if poi_note.poi == @poi
            new_poi_notes << poi_note
            poi_note_json_list << poi_note_json(poi_note)
          end
        else
          Rails.logger.warn "poi_note[id=#{note_match[1]}] found in diff from user/branch #{@user.id}/#{vm.cur_branch} but not in db"
        end
      end
    end

    min_local_time_secs = -1
    params[:poi_note_ids].each do |poi_note_id|
      poi_note_local_time_secs = poi_note_id.abs # (poi_note_id.to_i/1000).round.abs
      min_local_time_secs = poi_note_local_time_secs if (min_local_time_secs == -1) || (poi_note_local_time_secs < min_local_time_secs)

      file = params[:poi_note][poi_note_id][:file]
      if file.present? || (embed = params[:poi_note][poi_note_id][:embed]).present?
        upload = Upload.new(attached_to: PoiNote.new(poi: @poi, user: @user, text: params[:poi_note][poi_note_id][:text], local_time_secs: poi_note_local_time_secs))
        upload.attached_to.attachment = upload
        if file.present?
          upload.build_entity file.content_type, file: file
        else
          upload.build_entity :embed, text: embed[:content], embed_type: UploadEntity::Embed.get_embed_type(embed[:content])
        end
        poi_note = upload.attached_to
      else
        poi_note = PoiNote.new(poi: @poi, user: @user, text: params[:poi_note][poi_note_id][:text], local_time_secs: poi_note_local_time_secs)
      end
      @poi.notes << poi_note
      new_poi_notes << poi_note
    end
    @poi.local_time_secs = min_local_time_secs if is_new_poi

    if @poi.save
      # vm
      vm.add_poi @poi
      
      (@poi.notes.length-params[:poi_note_ids].length..(@poi.notes.length-1)).each do |idx|
        # show local_time_secs only to creator
        poi_note_json_list << poi_note_json(@poi.notes[idx], false).
                              merge!(@poi.notes[idx].user==@user ? {local_time_secs: @poi.notes[idx].local_time_secs} : {})
        # vm
        vm.add_poi_note @poi, @poi.notes[idx]
      end

      # vm
      vm.merge true, true
      cur_commit = vm.cur_commit
      
      @poi.update_attribute :commit_hash, cur_commit unless @poi.commit_hash.present?
      new_poi_notes.each {|p_n|p_n.update_attribute(:commit_hash, cur_commit) unless p_n.commit_hash.present?}
      commit = @user.commits.create hash_id: cur_commit, timestamp: DateTime.now, local_time_secs: params[:poi_note_ids].first.to_i.abs # (params[:poi_note_ids].first.to_i/1000).round.abs
      @user.snapshot.update_attribute :cur_commit, commit
      
      @poi_json = poi_json(@poi).
                  merge!(@poi.user==@user ? {local_time_secs: @poi.local_time_secs} : {})
      @poi_json[:user] = { id: @user.id }
      @poi_json[:notes] = poi_note_json_list
      
      data = @poi_json.to_json
      render json: data
    
      # http://stackoverflow.com/questions/552659/assigning-git-sha1s-without-git
      # "blob " + filesize + "\0" + data
#      commit_hash = Digest::SHA1.new << "blob #{data.size}\0#{data}"
#      @poi.update_attribute :commit_hash, commit_hash
#      new_poi_notes.each {|p_n|p_n.update_attribute(:commit_hash, commit_hash)}

      after_sync
    else
      render json: { errors: @poi.errors.full_messages }, status: 401
    end
  end

  # creates a poi with initial poi_note or adds poi_note to poi's initial poi_note
  def create
    user = current_user || tmp_user
    poi = nearby_poi user, Location.new(latitude: params[:location][:latitude], longitude: params[:location][:longitude])
    is_new_poi = poi.notes.empty? # if not before then it was persisted? in nearby_poi
    # FIXME - if poi exists then add new note as comment to poi's initial poi_note and set comments_on
    user.locations << poi.location unless user.locations.find {|l|l.id==poi.location.id}

    poi_note_params = { poi: poi, user: user, text: params[:poi_note][:text] }
    attached_to = PoiNote.new poi_note_params
    unless is_new_poi
      attached_to.comments_on = poi.notes.first
      poi.notes.first.comments << attached_to
    end
    @upload = Upload.new(attached_to: attached_to)
    @upload.attached_to.attachment = @upload
    @upload.build_entity params[:poi_note][:file].content_type, file: params[:poi_note][:file]

    if @upload.save
      #vm
      new_version user, poi, is_new_poi, @upload.attached_to

      @poi_note_json = poi_note_json @upload.attached_to
      #render "uploads/uploaded", layout: 'uploads', formats: [:html], locals: { resource: @upload, resource_name: :upload }
      render json: @poi_note_json.to_json
    
      after_save
    else
      #render "uploads/uploaded", layout: 'uploads', formats: [:html], locals: { resource: @upload, resource_name: :upload }
      render json: { errors: @upload.errors.full_messages }, status: 401
    end
  end

  # adds a comment to a poi_note
  def update
    user = current_user || tmp_user
    @poi_note = PoiNote.find(params[:id])
    user.locations << @poi_note.poi.location unless user.locations.find {|l|l.id==@poi_note.poi.location.id}

    upload = Upload.new
    upload.build_entity params[:poi_note][:file].content_type, file: params[:poi_note][:file]
    comment = @poi_note.comments.build(poi: @poi_note.poi, user: user, text: params[:poi_note][:text], attachment: upload)
    upload.attached_to = comment
    comment.save
    
    #vm
    new_version user, @poi_note.poi, false, upload.attached_to

    @upload = comment.attachment
    @poi_note_json = poi_note_json @upload.attached_to
    
    #render "uploads/uploaded", layout: 'uploads', formats: [:html], locals: { resource: @upload, resource_name: :upload }
    render json: @poi_note_json.to_json
    
    after_save
  end

  def create_from_base64
    user = current_user || tmp_user
    poi = nearby_poi user, Location.new(latitude: params[:location][:latitude], longitude: params[:location][:longitude])
    is_new_poi = poi.notes.empty? # if not before then it was persisted? in nearby_poi
    # FIXME - if poi exists then add new note as comment to poi's initial poi_note and set comments_on
    user.locations << poi.location unless user.locations.find {|l|l.id==poi.location.id}
    
    attachment_mapping = Upload.get_attachment_mapping params[:file_content_type]
    @upload = build_upload_base64 user, poi, attachment_mapping
    
    if @upload.attached_to.save
      #vm
      new_version user, poi, is_new_poi, @upload.attached_to

      if attachment_mapping.size >= 2
        # restore original content-type after imagemagick did it's job
        suffix = ".#{params[:file_content_type].match(/^[^\/]+\/([^\s;,]+)/)[1]}" rescue ''
        File.rename(@upload.entity.file.path, @upload.entity.file.path.sub(/\.[^.]+$/, suffix))
        @upload.entity.update_attributes(file_file_name: @upload.entity.file_file_name.sub(/\.[^.]+$/, suffix), file_content_type: params[:file_content_type])
      end
      #render "uploads/uploaded_base64", formats: [:js]
      @poi_note_json = poi_note_json @upload.attached_to
      render json: @poi_note_json.to_json
    
      after_save
    else
      #render "uploads/uploaded_base64", formats: [:js]
      render json: { error: 'failed' }, status: 401
    end
  end

  # adds a comment
  def update_from_base64
    user = current_user || tmp_user
    @poi_note = PoiNote.find(params[:id])
    user.locations << @poi_note.poi.location unless user.locations.find {|l|l.id==@poi_note.poi.location.id}
    
    attachment_mapping = Upload.get_attachment_mapping params[:file_content_type]

    @upload = build_upload_base64 user, @poi_note.poi, attachment_mapping
    @poi_note.comments << @upload.attached_to
    @poi_note.save

    #vm
    new_version user, @poi_note.poi, false, @upload.attached_to

    if attachment_mapping.size >= 2
      # restore original content-type after imagemagick did it's job
      suffix = ".#{params[:file_content_type].match(/^[^\/]+\/([^\s;,]+)/)[1]}" rescue ''
      File.rename(@upload.entity.file.path, @upload.entity.file.path.sub(/\.[^.]+$/, suffix))
      @upload.entity.update_attributes(file_file_name: @upload.entity.file_file_name.sub(/\.[^.]+$/, suffix), file_content_type: params[:file_content_type])
    end
    
    #render "uploads/uploaded_base64", formats: [:js]
    @poi_note_json = poi_note_json @upload.attached_to
    render json: @poi_note_json.to_json

    after_save
  end

  def create_from_embed
    user = current_user || tmp_user
    poi = nearby_poi user, Location.new(latitude: params[:location][:latitude], longitude: params[:location][:longitude])
    is_new_poi = poi.notes.empty? # if not before then it was persisted? in nearby_poi
    # FIXME - if poi exists then add new note as comment to poi's initial poi_note and set comments_on
    user.locations << poi.location unless user.locations.find {|l|l.id==poi.location.id}

    @upload = Upload.new(attached_to: PoiNote.new(poi: poi, user: user, text: params[:comment]))
    @upload.attached_to.attachment = @upload
    @upload.build_entity :embed, text: params[:data], embed_type: UploadEntity::Embed.get_embed_type(params[:data])
    
    if @upload.attached_to.save
      #vm
      new_version user, poi, is_new_poi, @upload.attached_to

      #render "uploads/uploaded_base64", formats: [:js]
      @poi_note_json = poi_note_json @upload.attached_to
      render json: @poi_note_json.to_json
    
      after_save
    else
      #render "uploads/uploaded_base64", formats: [:js]
      render json: { error: 'failed' }, status: 401
    end
  end

  # adds a comment
  def update_from_embed
    user = current_user || tmp_user
    @poi_note = PoiNote.find(params[:id])
    user.locations << @poi_note.poi.location unless user.locations.find {|l|l.id==@poi_note.poi.location.id}

    @upload = Upload.new
    @upload.build_entity :embed, text: params[:data], embed_type: UploadEntity::Embed.get_embed_type(params[:data])
    comment = @poi_note.comments.build(poi: @poi_note.poi, user: user, text: params[:comment], attachment: @upload)
    @upload.attached_to = comment
    comment.save
    comment.reload

    #vm
    new_version user, @poi_note.poi, false, comment
    
    #render "uploads/uploaded_base64", formats: [:js]
    @poi_note_json = poi_note_json comment
    render json: @poi_note_json.to_json

    after_save
  end

  def create_from_plain_text
    user = current_user || tmp_user
    poi = nearby_poi user, Location.new(latitude: params[:location][:latitude], longitude: params[:location][:longitude])
    is_new_poi = poi.notes.empty? # if not before then it was persisted? in nearby_poi
    # FIXME - if poi exists then add new note as comment to poi's initial poi_note and set comments_on
    user.locations << poi.location unless user.locations.find {|l|l.id==poi.location.id}

    poi_note = PoiNote.new(poi: poi, user: user, text: params[:comment])
    
    if poi_note.save
      #vm
      new_version user, poi, is_new_poi, poi_note

      #render "uploads/uploaded_base64", formats: [:js]
      @poi_note_json = poi_note_json poi_note
      render json: @poi_note_json.to_json
    
      after_save
    else
      #render "uploads/uploaded_base64", formats: [:js]
      render json: { error: 'failed' }, status: 401
    end
  end

  # adds a comment
  def update_from_plain_text
    user = current_user || tmp_user
    @poi_note = PoiNote.find(params[:id])
    user.locations << @poi_note.poi.location unless user.locations.find {|l|l.id==@poi_note.poi.location.id}

    comment = @poi_note.comments.build(poi: @poi_note.poi, user: user, text: params[:comment])
    comment.save
    
    #vm
    new_version user, @poi_note.poi, false, comment
    
    #render "uploads/uploaded_base64", formats: [:js]
    @poi_note_json = poi_note_json comment
    render json: @poi_note_json.to_json

    after_save
  end

  def destroy
    # TODO don't delete if first poiNote - can only be deleted via poi
    @upload = Upload.find(params[:id])
    @upload.attached_to.destroy
    render "uploads/deleted", formats: [:js]
  end

  def pois
    user = current_user || tmp_user

    pois_json = []
    @pois = nearby_pois Location.new(latitude: params[:lat], longitude: params[:lng]), (user.search_radius_meters||1000)
    @pois.each do |poi|
      pois_json << poi_json(poi)
    end
    
    render json: {pois: pois_json}.to_json
  end

  def comments
    user = current_user || tmp_user
    if params[:poi_note_id] != '-1'
      poi_note = PoiNote.find(params[:poi_note_id])
      poi = poi_note.poi
    else
      poi_note = nil
      poi = Poi.find(params[:poi_id]) if params[:poi_id].present?
    end

    poi_json = poi_json poi
    poi_json[:notes] = poi_notes_as_list poi, poi_note

    render json: {poi: poi_json}.to_json
  end

  def csrf
    render "shared/csrf", layout: 'uploads'
  end

  private

  # TODO local_time_secs
  def new_version user, poi, is_new_poi, poi_note, local_time_secs = nil
    vm = VersionManager.new UploadsController::MASTER, UploadsController::WORK_DIR_ROOT, user, false#@user.is_admin
    prev_commit = vm.cur_commit
    vm.add_poi poi if is_new_poi
    vm.add_poi_note poi, poi_note
    vm.merge true, true
    cur_commit = vm.cur_commit
    poi.update_attribute :commit_hash, cur_commit unless poi.commit_hash.present?
    poi_note.update_attribute :commit_hash, cur_commit
    commit = user.commits.create hash_id: cur_commit, timestamp: DateTime.now#, local_time_secs: params[:local_time_secs]
    user.snapshot.update_attribute :cur_commit, commit
  end

  def after_sync
    upload_msg = { type: 'poi_sync',
                   poi: @poi_json }

    channel_path = '/uploads'
    channel_path += "#{PEER_CHANNEL_PREFIX}#{@user.comm_setting.channel_enc_key}" unless USE_GLOBAL_SUBSCRIBE
    Comm::ChannelsController.publish(channel_path, upload_msg)
  end

  def after_save
    #geometry = Paperclip::Geometry.from_file(@upload.file)
    #file_data = { type: 'image', url: @upload.file.url, width: geometry.width.to_i, height: geometry.height.to_i }
    #location_data = { lat: @upload.attached_to.poi.location.latitude, lng: @upload.attached_to.poi.location.longitude, address: shorten_address(@upload.attached_to.poi.location) }
    #upload_msg = { id: @upload.id, file: file_data, location: location_data }
    #poi_note = @upload.attached_to
    upload_msg = { type: 'poi_note_upload',
#                   poi_note: poi_note_json(poi_note) }
                   poi_note: @poi_note_json }

    channel_path = '/uploads'
    channel_path += "#{PEER_CHANNEL_PREFIX}#{@upload.attached_to.user.comm_setting.channel_enc_key}" unless USE_GLOBAL_SUBSCRIBE
    Comm::ChannelsController.publish(channel_path, upload_msg)
  end
end
