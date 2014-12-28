class UploadsController < ApplicationController 
  include GeoUtils

  skip_before_filter :verify_authenticity_token, only: [:create, :update]

  def index
    render layout: 'uploads'
  end

  def create
    user = current_user || tmp_user
    poi = nearby_poi user, Location.new(latitude: params[:location][:latitude], longitude: params[:location][:longitude])
    
    @upload = Upload.new(attached_to: PoiNote.new(poi: poi, user: user, text: params[:poi_note][:text]))
    @upload.attached_to.attachment = @upload
    @upload.build_entity params[:poi_note][:file].content_type, file: params[:poi_note][:file]
    
    if @upload.save
      @poi_note_json = poi_note_json @upload.attached_to
      render "uploads/uploaded", layout: 'uploads', formats: [:html], locals: { resource: @upload, resource_name: :upload }
    else
      render "uploads/uploaded", layout: 'uploads', formats: [:html], locals: { resource: @upload, resource_name: :upload }
    end
    after_save
  end

  # adds a comment
  def update
    user = current_user || tmp_user
    @poi_note = PoiNote.find(params[:id])

    upload = Upload.new
    upload.build_entity params[:poi_note][:file].content_type, file: params[:poi_note][:file]
    comment = @poi_note.comments.build(poi: @poi_note.poi, user: user, text: params[:poi_note][:text], attachment: upload)
    upload.attached_to = comment
    comment.save
    
    @upload = comment.attachment
    @poi_note_json = poi_note_json @upload.attached_to
    
    render "uploads/uploaded", layout: 'uploads', formats: [:html], locals: { resource: @upload, resource_name: :upload }
    after_save
  end

  def create_from_base64
    user = current_user || tmp_user
    poi = nearby_poi user, Location.new(latitude: params[:location][:latitude], longitude: params[:location][:longitude])
    
    attachment_mapping = Upload.get_attachment_mapping params[:file_content_type]
    @upload = build_upload_base64 user, poi, attachment_mapping
    
    if @upload.attached_to.save
      if attachment_mapping.size >= 2
        # restore original content-type after imagemagick did it's job
        suffix = ".#{params[:file_content_type].match(/^[^\/]+\/([^\s;,]+)/)[1]}" rescue ''
        File.rename(@upload.entity.file.path, @upload.entity.file.path.sub(/\.[^.]+$/, suffix))
        @upload.entity.update_attributes(file_file_name: @upload.entity.file_file_name.sub(/\.[^.]+$/, suffix), file_content_type: params[:file_content_type])
      end
      #render "uploads/uploaded_base64", formats: [:js]
      poi_note_json = poi_note_json @upload.attached_to
      render json: poi_note_json.to_json
    else
      #render "uploads/uploaded_base64", formats: [:js]
      render json: { error: 'failed' }, status: 401
    end
    after_save
  end

  # adds a comment
  def update_from_base64
    user = current_user || tmp_user
    @poi_note = PoiNote.find(params[:id])
    
    attachment_mapping = Upload.get_attachment_mapping params[:file_content_type]

    @upload = build_upload_base64 user, @poi_note.poi, attachment_mapping
    @poi_note.comments << @upload.attached_to
    @poi_note.save

    if attachment_mapping.size >= 2
      # restore original content-type after imagemagick did it's job
      suffix = ".#{params[:file_content_type].match(/^[^\/]+\/([^\s;,]+)/)[1]}" rescue ''
      File.rename(@upload.entity.file.path, @upload.entity.file.path.sub(/\.[^.]+$/, suffix))
      @upload.entity.update_attributes(file_file_name: @upload.entity.file_file_name.sub(/\.[^.]+$/, suffix), file_content_type: params[:file_content_type])
    end
    
    #render "uploads/uploaded_base64", formats: [:js]
    poi_note_json = poi_note_json @upload.attached_to
    render json: poi_note_json.to_json

    after_save
  end

  def destroy
    @upload = Upload.find(params[:id])
    @upload.attached_to.destroy
    render "uploads/deleted", formats: [:js]
  end

  def pois
    user = current_user || tmp_user

    pois_json = []
    @pois = nearby_pois user, Location.new(latitude: params[:lat], longitude: params[:lng]), (user.search_radius_meters||1000)
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

    poi_notes = []
    poi.notes.where('comments_on_id is null').each do |p_n|
      poi_notes << poi_note_json(p_n, false)
      p_n.comments.each do |p_n_2|
        poi_notes << poi_note_json(p_n_2, false)
        if poi_note.present? && p_n_2 == poi_note
          # only recurse for requested
          addToThread poi_note, poi_notes
        end
      end
    end
    poi_json = poi_json poi
    poi_json[:notes] = poi_notes

    render json: {poi: poi_json}.to_json
  end

  def csrf
    render "shared/csrf", layout: 'uploads'
  end

  private

  def add_attachment_to_poi_note_json upload, poi_note_json
    if upload.entity is_a? UploadEntity::Mediafile
      case upload.entity.content_type.match(/^[^\/]+/)[0]
      when 'image'
        geometry = Paperclip::Geometry.from_file(upload.entity.file)
        poi_note_json[:attachment] = { content_type: upload.entity.file.content_type, id: upload.id, url: upload.entity.file.url, width: geometry.width.to_i, height: geometry.height.to_i }
      when 'audio'
        poi_note_json[:attachment] = { content_type: upload.entity.file.content_type, id: upload.id, url: upload.entity.file.url }
      when 'video'
        poi_note_json[:attachment] = { content_type: upload.entity.file.content_type, id: upload.id, url: upload.entity.file.url }
      else
        poi_note_json[:attachment] = { content_type: 'unknown/unknown', id: upload.id, url: upload.entity.file.url }
      end
    else
      poi_note_json[:attachment] = { content_type: 'unknown/unknown', id: upload.id, url: nil }
    end
  end

  def build_upload_base64 user, poi, attachment_mapping
    upload = Upload.new(attached_to: PoiNote.new(poi: poi, user: user, text: params[:file_comment]))
    if attachment_mapping.size >= 2
      file_name = "#{user.username}.#{attachment_mapping[1]}" 
    else
      suffix = ".#{params[:file_content_type].match(/^[^\/]+\/([^\s;,]+)/)[1]}" rescue ''
      file_name = "#{user.username}#{suffix}" 
    end
    upload.build_entity params[:file_content_type]
    upload.entity.set_base64_file params[:file_data], attachment_mapping[0], file_name
    upload.attached_to.attachment = upload
    upload
  end
  
  def poi_json poi
    poi_json = { id: poi.id,
                 lat: poi.location.latitude,
                 lng: poi.location.longitude,
                 address: poi.location.address }
  end
  
  def poi_note_json poi_note, with_poi = true
    poi_note_json = { id: poi_note.id,
                      user: { id: poi_note.user.id,
                              username: poi_note.user.username },
                      text: poi_note.text }
    poi_note_json[:poi] = poi_json poi_note.poi if with_poi
    add_attachment_to_poi_note_json poi_note.attachment, poi_note_json
    poi_note_json
  end

  def addToThread poi_note, comments
    poi_note.comments.each do |p_n|
      comments << poi_note_json(p_n, false)
      addToThread p_n, comments
    end
  end

  def after_save
    #geometry = Paperclip::Geometry.from_file(@upload.file)
    #file_data = { type: 'image', url: @upload.file.url, width: geometry.width.to_i, height: geometry.height.to_i }
    #location_data = { lat: @upload.attached_to.poi.location.latitude, lng: @upload.attached_to.poi.location.longitude, address: @upload.attached_to.poi.location.address }
    #upload_msg = { id: @upload.id, file: file_data, location: location_data }
    poi_note = @upload.attached_to
    upload_msg = { type: 'poi_note_upload',
                   poi_note: poi_note_json(poi_note) }

    channel_path = '/uploads'
    channel_path += "#{PEER_CHANNEL_PREFIX}#{@upload.attached_to.user.comm_setting.channel_enc_key}" unless USE_GLOBAL_SUBSCRIBE
    Comm::ChannelsController.publish(channel_path, upload_msg)
  end
end
