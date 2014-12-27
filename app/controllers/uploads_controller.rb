class UploadsController < ApplicationController 
  include GeoUtils

  skip_before_filter :verify_authenticity_token, only: [:create, :update]

  def index
    render layout: 'uploads'
  end

  def create
    user = current_user || tmp_user
    poi = nearby user, Location.new(latitude: params[:location][:latitude], longitude: params[:location][:longitude])
    
    @upload = Upload.new(attached_to: PoiNote.new(poi: poi, user: user, text: params[:poi_note][:text]))
    @upload.attached_to.attachment = @upload
    @upload.build_entity params[:poi_note][:file].content_type, file: params[:poi_note][:file]
    
    if @upload.save
      @poi_note_json = poi_note_json(@upload.attached_to)
      render "shared/uploaded", layout: 'uploads', formats: [:html], locals: { resource: @upload, resource_name: :upload }
    else
      render "shared/uploaded", layout: 'uploads', formats: [:html], locals: { resource: @upload, resource_name: :upload }
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
    @poi_note_json = poi_note_json(@upload.attached_to)
    
    render "shared/uploaded", layout: 'uploads', formats: [:html], locals: { resource: @upload, resource_name: :upload }
    after_save
  end

  def create_from_base64
    user = current_user || tmp_user
    poi = nearby user, Location.new(latitude: params[:location][:latitude], longitude: params[:location][:longitude])
    
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
      poi_note_json = poi_note_json(@upload.attached_to)
      render json: poi_note_json
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
    poi_note_json = poi_note_json(@upload.attached_to)
    render json: poi_note_json

    after_save
  end

  def destroy
    @upload = Upload.find(params[:id])
    @upload.attached_to.destroy
    render "uploads/deleted", formats: [:js]
  end

  def comments
    user = current_user || tmp_user
    poi_note = PoiNote.find(params[:upload_id])
    @upload = poi_note.attachment
    
    poi_notes = []
    cur_poi_note = @upload.attached_to
    cur_poi_note_json = { id: cur_poi_note.id,
                          user: { id: cur_poi_note.user.id,
                                  username: cur_poi_note.user.username },
                          text: cur_poi_note.text }
    add_attachment_to_poi_note_json @upload, cur_poi_note_json
    poi_notes << cur_poi_note_json
    @upload.attached_to.comments.each do |cur_poi_note|
      cur_poi_note_json = { id: cur_poi_note.id,
                            user: { id: cur_poi_note.user.id,
                                    username: cur_poi_note.user.username },
                            text: cur_poi_note.text }
      add_attachment_to_poi_note_json cur_poi_note.attachment, cur_poi_note_json
      poi_notes << cur_poi_note_json
    end
    json = { poi: { id: @upload.attached_to.poi.id,
                    lat: @upload.attached_to.poi.location.latitude,
                    lng: @upload.attached_to.poi.location.longitude,
                    address: @upload.attached_to.poi.location.address,
                    notes: poi_notes } }
    render json: json
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

  def nearby user, location
    # FIXME:
    # 1) when address is available check same address
    # 2) otherwise range
   #nearbys = location.nearbys(0.01)
    limits = latLngLimits(location.latitude, location.longitude, 10)
    limits_lat = limits[:lat_south] > limits[:lat_north] ? limits[:lat_north]..limits[:lat_south] : limits[:lat_south]..limits[:lat_north]
    limits_lng = limits[:lng_east] > limits[:lng_west] ? limits[:lng_west]..limits[:lng_east] : limits[:lng_east]..limits[:lng_west]
    nearbys = Poi.joins(:location).where(locations: { latitude: limits_lat, longitude: limits_lng })
    if nearbys.present?
      poi = nearbys.first
      unless user.locations.where(id: poi.location.id).present?
        user.locations_users.create(location: poi.location)
      end
    else
      location.save
      poi = Poi.new location: location
      user.locations_users.create(location: location)
    end
    poi
  end
  
  def poi_note_json poi_note
    poi_note_json = { poi: { id: poi_note.poi.id,
                             lat: poi_note.poi.location.latitude,
                             lng: poi_note.poi.location.longitude,
                             address: poi_note.poi.location.address },
                      id: poi_note.id,
                      user: { id: poi_note.user.id,
                              username: poi_note.user.username },
                      text: poi_note.text } 
    add_attachment_to_poi_note_json poi_note.attachment, poi_note_json
    poi_note_json
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
