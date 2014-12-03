class SandboxController < ApplicationController
  include ::AuthUtils

  def index
    unless tmp_user.comm_setting.present?
      comm_setting = CommSetting.create(user: tmp_user, channel_enc_key: enc_key)
    end
    @initial_subscribe = true
    
    nearby_km = (tmp_user.search_radius_meters||20000)/1000
    location = tmp_user.last_location
    #@uploads = location.nearbys((nearby_km.to_f/1.609344).round).inject([]){|res,l|l.uploads.where('uploads.location_id is not null')}
    @uploads = Upload.all.order('location_id, id desc')
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
    nearby_km = (tmp_user.search_radius_meters||20000)/1000
    location = tmp_user.last_location
    #@uploads = location.nearbys((nearby_km.to_f/1.609344).round).inject([]){|res,l|l.uploads.where('uploads.location_id is not null')}
    @uploads = Upload.all.order('location_id, id desc')
    render "sandbox/photo_nav", layout: false, formats: [:js]
  end

end
