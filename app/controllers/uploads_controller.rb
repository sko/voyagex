class UploadsController < ApplicationController 
  include GeoUtils

  skip_before_filter :verify_authenticity_token, only: [:create, :update]

  def create
    user = current_user || tmp_user
    poi = nearby user, Location.new(latitude: params[:location][:latitude], longitude: params[:location][:longitude])
    @upload = Upload.new poi_note: PoiNote.new(poi: poi, user: user, text: params[:upload_comment][:text])
    @upload.build_entity params[:upload][:file].content_type, file: params[:upload][:file]
    if @upload.save
      render "shared/uploaded", layout: 'uploads', formats: [:html], locals: { resource: @upload, resource_name: :upload }
    else
      render "shared/uploaded", layout: 'uploads', formats: [:html], locals: { resource: @upload, resource_name: :upload }
    end
    after_save
  end

  def create_from_base64
    user = current_user || tmp_user
    poi = nearby user, Location.new(latitude: params[:location][:latitude], longitude: params[:location][:longitude])
    attachment_mapping = Upload.get_attachment_mapping params[:file_content_type]
    @upload = build_upload_base64 user, poi, attachment_mapping
    if @upload.save
      if attachment_mapping.size >= 2
        # restore original content-type after imagemagick did it's job
        suffix = ".#{params[:file_content_type].match(/^[^\/]+\/([^\s;,]+)/)[1]}" rescue ''
        File.rename(@upload.entity.file.path, @upload.entity.file.path.sub(/\.[^.]+$/, suffix))
        @upload.entity.update_attributes(file_file_name: @upload.entity.file_file_name.sub(/\.[^.]+$/, suffix), file_content_type: params[:file_content_type])
      end
      render "uploads/uploaded_base64", formats: [:js]
    else
      render "uploads/uploaded_base64", formats: [:js]
    end
    after_save
  end

  # adds a comment
  def update
    user = current_user || tmp_user
    @upload = Upload.find(params[:id])
    #comment_attachment = build_upload_base64 user, @upload.poi_note.poi, attachment_mapping
    comment_attachment = Upload.new
    comment_attachment.build_entity params[:upload][:file].content_type, file: params[:upload][:file]
    comment = @upload.poi_note.comments.create(poi: @upload.poi_note.poi, user: user, text: params[:upload_comment][:text], attachment: comment_attachment)
    render "shared/uploaded", layout: 'uploads', formats: [:html], locals: { resource: @upload, resource_name: :upload }
    after_save
  end

  # adds a comment
  def update_from_base64
    user = current_user || tmp_user
    @upload = Upload.find(params[:id])
    attachment_mapping = Upload.get_attachment_mapping params[:file_content_type]
    comment_attachment = build_upload_base64 user, @upload.poi_note.poi, attachment_mapping
    comment = @upload.poi_note.comments.create(poi: @upload.poi_note.poi, user: user, text: params[:file_comment], attachment: comment_attachment)
    if attachment_mapping.size >= 2
      # restore original content-type after imagemagick did it's job
      suffix = ".#{params[:file_content_type].match(/^[^\/]+\/([^\s;,]+)/)[1]}" rescue ''
      File.rename(comment.attachment.entity.file.path, comment.attachment.entity.file.path.sub(/\.[^.]+$/, suffix))
      comment.attachment.entity.update_attributes(file_file_name: comment.attachment.entity.file_file_name.sub(/\.[^.]+$/, suffix), file_content_type: params[:file_content_type])
    end
    render "uploads/uploaded_base64", formats: [:js]
    after_save
  end

  def comments
    user = current_user || tmp_user
    @upload = Upload.find(params[:upload_id])
    if params[:text].present?
      @upload.comments.create(user: user, text: params[:text])
    end
    render "shared/upload_comments", layout: false, formats: [:js]
  end

  def csrf
    render "shared/csrf", layout: 'uploads'
  end

  private

  def build_upload_base64 user, poi, attachment_mapping
    upload = Upload.new poi_note: PoiNote.new(poi: poi, user: user, text: params[:file_comment])
    if attachment_mapping.size >= 2
      file_name = "#{user.username}.#{attachment_mapping[1]}" 
    else
      suffix = ".#{params[:file_content_type].match(/^[^\/]+\/([^\s;,]+)/)[1]}" rescue ''
      file_name = "#{user.username}#{suffix}" 
    end
    upload.build_entity params[:file_content_type]
    upload.entity.set_base64_file params[:file_data], attachment_mapping[0], file_name
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
  
  def after_save
    geometry = Paperclip::Geometry.from_file(@upload.file)
    file_data = { type: 'image', url: @upload.file.url, width: geometry.width.to_i, height: geometry.height.to_i }
    location_data = { lat: @upload.poi_note.poi.location.latitude, lng: @upload.poi_note.poi.location.longitude, address: @upload.poi_note.poi.location.address }
    upload_msg = { id: @upload.id, file: file_data, location: location_data }
    channel_path = '/uploads'
    channel_path += "#{PEER_CHANNEL_PREFIX}#{@upload.poi_note.user.comm_setting.channel_enc_key}" unless USE_GLOBAL_SUBSCRIBE
    Comm::ChannelsController.publish(channel_path, upload_msg)
  end
end
