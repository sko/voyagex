class SandboxController < ApplicationController

  def index
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

end
