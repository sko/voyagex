class SandboxController < ApplicationController
  include ::AuthUtils
  include ::GeoUtils

  # used when loading a location on the map 
  def location
    @location = Location.find(params[:location_id])
    nearby_m = (tmp_user.search_radius_meters||20000)
    load_location_data @location, nearby_m
  end

  # used from Model.js to act withLocation
  def location_data
    location = Location.find(params[:location_id])
    location_json = {lat: location.latitude, lng: location.longitude, address: shorten_address(location)}
    poi = Poi.where(location_id: location.id).first
    location_json[:poi_id] = poi.id if poi.present?
    render json: location_json.to_json
  end

  def index
    unless tmp_user.comm_setting.present?
      comm_setting = CommSetting.create(user: tmp_user, channel_enc_key: enc_key, sys_channel_enc_key: enc_key)
    end
    @initial_subscribe = true
    unless tmp_user.foto.exists?
      avatar_image_data = UserHelper::fetch_random_avatar request
      cur_path = Rails.root.join('public', 'assets', 'fotos', 'random_avatar')
      File.open(cur_path, 'wb'){|file| file.write(avatar_image_data[1])}
      tmp_user.update_attribute :foto, File.new(cur_path)
    end
    if tmp_user.last_sign_in_ip.present?
      unless tmp_user.snapshot.cur_commit_hash.present?
        vm = VersionManager.new UploadsController::MASTER, UploadsController::WORK_DIR_ROOT, tmp_user, false#user.is_admin
        tmp_user.snapshot.update_attribute :cur_commit_hash, vm.cur_commit
      end
    end

    nearby_m = (tmp_user.search_radius_meters||20000)
    location = tmp_user.snapshot.location.present? ? tmp_user.snapshot.location : tmp_user.last_location
    if location.present?
      load_location_data location, nearby_m
    else
      @pois = []
      @uploads = []
    end
    #@uploads = Upload.all.order('location_id, id desc')
    # https://github.com/alexreisner/geocoder#request-geocoding-by-ip-address
#[1] pry(#<SandboxController>)> request.location
#=> #<Geocoder::Result::Freegeoip:0xf7a3c08
# @cache_hit=false,
# @data=
#  {"ip"=>"2.207.225.240",
#   "country_code"=>"DE",
#   "country_name"=>"Germany",
#   "region_code"=>"",
#   "region_name"=>"",
#   "city"=>"",
#   "zip_code"=>"",
#   "time_zone"=>"",
#   "latitude"=>51,
#   "longitude"=>9,
#   "metro_code"=>0}>
  end

  def photo_nav
    nearby_m = (tmp_user.search_radius_meters||20000)
    location = Location.new latitude: params[:lat], longitude: params[:lng]
# GOOD but now from template ...  load_location_data location, nearby_m
    render "sandbox/photo_nav", layout: false, formats: [:js]
  end

  private

  def load_location_data location, nearby_m
    #@uploads = location.nearbys((nearby_km.to_f/1.609344).round).inject([]){|res,l|l.uploads.where('uploads.location_id is not null')}
    limits = lat_lng_limits location.latitude, location.longitude, nearby_m
    limits_lat = limits[:lat_south] > limits[:lat_north] ? limits[:lat_north]..limits[:lat_south] : limits[:lat_south]..limits[:lat_north]
    limits_lng = limits[:lng_east] > limits[:lng_west] ? limits[:lng_west]..limits[:lng_east] : limits[:lng_east]..limits[:lng_west]
    @pois = Poi.joins(:location).where(locations: {latitude: limits_lat, longitude: limits_lng})
    @uploads = Upload.joins(attached_to: { poi: :location }).where(locations: {latitude: limits_lat, longitude: limits_lng})
  end
end
