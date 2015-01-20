class UploadsController < ApplicationController 
  include GeoUtils
  include ApplicationHelper
  include PoiHelper

  skip_before_filter :verify_authenticity_token, only: [:create, :update]

  def index
    render layout: 'uploads'
  end

  def create
    user = current_user || tmp_user
    poi = nearby_poi user, Location.new(latitude: params[:location][:latitude], longitude: params[:location][:longitude])
    user.locations << poi.location unless user.locations.find {|l|l.id==poi.location.id}

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
    user.locations << @poi_note.poi.location unless user.locations.find {|l|l.id==@poi_note.poi.location.id}

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
    user.locations << poi.location unless user.locations.find {|l|l.id==poi.location.id}
    
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
    user.locations << @poi_note.poi.location unless user.locations.find {|l|l.id==@poi_note.poi.location.id}
    
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

  def create_from_embed
    user = current_user || tmp_user
    poi = nearby_poi user, Location.new(latitude: params[:location][:latitude], longitude: params[:location][:longitude])
    user.locations << poi.location unless user.locations.find {|l|l.id==poi.location.id}

    @upload = Upload.new(attached_to: PoiNote.new(poi: poi, user: user, text: params[:comment]))
    @upload.attached_to.attachment = @upload
    @upload.build_entity 'text/*', text: params[:data], embed_type: UploadEntity::Embed.get_embed_type(params[:data])
    
    if @upload.attached_to.save
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
  def update_from_embed
    user = current_user || tmp_user
    @poi_note = PoiNote.find(params[:id])
    user.locations << @poi_note.poi.location unless user.locations.find {|l|l.id==@poi_note.poi.location.id}

    @upload = Upload.new
    @upload.build_entity 'text/*', text: params[:data], embed_type: UploadEntity::Embed.get_embed_type(params[:data])
    comment = @poi_note.comments.build(poi: @poi_note.poi, user: user, text: params[:comment], attachment: @upload)
    @upload.attached_to = comment
    comment.save
    comment.reload
    
    #render "uploads/uploaded_base64", formats: [:js]
    poi_note_json = poi_note_json comment
    render json: poi_note_json.to_json

    after_save
  end

  def create_from_plain_text
    user = current_user || tmp_user
    poi = nearby_poi user, Location.new(latitude: params[:location][:latitude], longitude: params[:location][:longitude])
    user.locations << poi.location unless user.locations.find {|l|l.id==poi.location.id}

    poi_note = PoiNote.new(poi: poi, user: user, text: params[:comment])
    
    if poi_note.save
      #render "uploads/uploaded_base64", formats: [:js]
      poi_note_json = poi_note_json poi_note
      render json: poi_note_json.to_json
    else
      #render "uploads/uploaded_base64", formats: [:js]
      render json: { error: 'failed' }, status: 401
    end
    
    after_save
  end

  # adds a comment
  def update_from_plain_text
    user = current_user || tmp_user
    @poi_note = PoiNote.find(params[:id])
    user.locations << @poi_note.poi.location unless user.locations.find {|l|l.id==@poi_note.poi.location.id}

    comment = @poi_note.comments.build(poi: @poi_note.poi, user: user, text: params[:comment])
    comment.save
    
    #render "uploads/uploaded_base64", formats: [:js]
    poi_note_json = poi_note_json comment
    render json: poi_note_json.to_json

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

  def after_save
    #geometry = Paperclip::Geometry.from_file(@upload.file)
    #file_data = { type: 'image', url: @upload.file.url, width: geometry.width.to_i, height: geometry.height.to_i }
    #location_data = { lat: @upload.attached_to.poi.location.latitude, lng: @upload.attached_to.poi.location.longitude, address: shorten_address(@upload.attached_to.poi.location) }
    #upload_msg = { id: @upload.id, file: file_data, location: location_data }
    poi_note = @upload.attached_to
    upload_msg = { type: 'poi_note_upload',
                   poi_note: poi_note_json(poi_note) }

    channel_path = '/uploads'
    channel_path += "#{PEER_CHANNEL_PREFIX}#{@upload.attached_to.user.comm_setting.channel_enc_key}" unless USE_GLOBAL_SUBSCRIBE
    Comm::ChannelsController.publish(channel_path, upload_msg)
  end
end
