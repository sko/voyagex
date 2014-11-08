# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)

#require 'faye'
#require File.expand_path('../comm/app', __FILE__)

#use Faye::RackAdapter, :mount      => '/comm',
#                       :timeout    => 25

run VoyageX::Application
