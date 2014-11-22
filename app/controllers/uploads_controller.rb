class UploadsController < ApplicationController 

  def create
    #user = current_user || User.where(id: params[:user][:id]).first || tmp_user
    user = current_user || tmp_user
    location = Location.new(latitude: params[:location][:latitude], longitude: params[:location][:longitude])
    nearbys = location.nearbys(0.01)
    if nearbys.present?
      location = nearbys.first
      unless user.locations.where(id: location.id).present?
        ls_u = user.locations_users.create(location: location)
      end
    else
      ls_u = user.locations_users.create(location: location)
    end
    @upload = Upload.new
    @upload.file = params[:upload][:file]
    @upload.location = location
    @upload.user = user
    if @upload.save
      @upload.comments.create(user: user, text: params[:upload_comment][:text])
    #render "shared/_uploaded", layout: false, formats: [:js], locals: { resource: @upload, resource_name: :upload }
      render "shared/uploaded", layout: 'uploads', formats: [:html], locals: { resource: @upload, resource_name: :upload }
    else
      render "shared/uploaded", layout: 'uploads', formats: [:html], locals: { resource: @upload, resource_name: :upload }
    end
    after_save
    #geometry = Paperclip::Geometry.from_file(@upload.file)
    #file_data = { type: 'image', url: @upload.file.url, width: geometry.width.to_i, height: geometry.height.to_i }
    #location_data = { lat: @upload.location.latitude, lng: @upload.location.longitude, address: @upload.location.address }
    #upload_msg = { id: @upload.id, file: file_data, location: location_data }
    #Comm::ChannelsController.publish('/uploads', upload_msg)
  end

  def create_from_base64
    user = current_user || tmp_user
    location = Location.new(latitude: params[:location_lat], longitude: params[:location_lng])
    # TODO nearby location check
    @upload = Upload.new
    file_name = "#{user.username}.class"
    @upload.set_base64_file params[:file_data], params[:file_content_type], file_name
    @upload.location = location
    @upload.user = user
    if @upload.save
      @upload.comments.create(user: user, text: params[:file_comment])
     #render "shared/_uploaded", layout: false, formats: [:js], locals: { resource: @upload, resource_name: :upload }
      render "shared/uploaded", layout: 'uploads', formats: [:html], locals: { resource: @upload, resource_name: :upload }
    else
      render "shared/uploaded", layout: 'uploads', formats: [:html], locals: { resource: @upload, resource_name: :upload }
    end
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

  private

  def after_save
    geometry = Paperclip::Geometry.from_file(@upload.file)
    file_data = { type: 'image', url: @upload.file.url, width: geometry.width.to_i, height: geometry.height.to_i }
    location_data = { lat: @upload.location.latitude, lng: @upload.location.longitude, address: @upload.location.address }
    upload_msg = { id: @upload.id, file: file_data, location: location_data }
    Comm::ChannelsController.publish('/uploads', upload_msg)
  end
end
