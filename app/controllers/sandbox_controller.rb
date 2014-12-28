class SandboxController < ApplicationController
  include ::AuthUtils
  include ::GeoUtils

  def index
    unless tmp_user.comm_setting.present?
      comm_setting = CommSetting.create(user: tmp_user, channel_enc_key: enc_key, sys_channel_enc_key: enc_key)
    end
    @initial_subscribe = true
    
    nearby_m = (tmp_user.search_radius_meters||20000)
    location = tmp_user.last_location
    if location.present?
      #@uploads = location.nearbys((nearby_km.to_f/1.609344).round).inject([]){|res,l|l.uploads.where('uploads.location_id is not null')}
      limits = lat_lng_limits location.latitude, location.longitude, nearby_m
      limits_lat = limits[:lat_south] > limits[:lat_north] ? limits[:lat_north]..limits[:lat_south] : limits[:lat_south]..limits[:lat_north]
      limits_lng = limits[:lng_east] > limits[:lng_west] ? limits[:lng_west]..limits[:lng_east] : limits[:lng_east]..limits[:lng_west]
      @pois = Poi.joins(:location).where(locations: {latitude: limits_lat, longitude: limits_lng})
      @uploads = Upload.joins(attached_to: { poi: :location }).where(locations: {latitude: limits_lat, longitude: limits_lng})
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
    #location = tmp_user.last_location
    location = Location.new latitude: params[:lat], longitude: params[:lng]
#    if location.present?
      #@uploads = location.nearbys((nearby_km.to_f/1.609344).round).inject([]){|res,l|l.uploads.where('uploads.location_id is not null')}
      limits = lat_lng_limits location.latitude, location.longitude, nearby_m
      limits_lat = limits[:lat_south] > limits[:lat_north] ? limits[:lat_north]..limits[:lat_south] : limits[:lat_south]..limits[:lat_north]
      limits_lng = limits[:lng_east] > limits[:lng_west] ? limits[:lng_west]..limits[:lng_east] : limits[:lng_east]..limits[:lng_west]
      @uploads = Upload.joins(attached_to: { poi: :location }).where(locations: {latitude: limits_lat, longitude: limits_lng})
#    else
#      @uploads = []
#    end
    #@uploads = Upload.all.order('location_id, id desc')
    render "sandbox/photo_nav", layout: false, formats: [:js]
  end

end
