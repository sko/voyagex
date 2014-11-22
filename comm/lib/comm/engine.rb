Faye::WebSocket.load_adapter('thin')

module Comm
  class Engine < ::Rails::Engine
  #class Engine < ::Faye::RackAdapter
    isolate_namespace Comm
    #config.action_controller.allow_concurrency true
    engine_params = [:development].include?(Rails.env) ? { engine: { type: Faye::Redis, host: 'localhost' } } : {}
    middleware.use FayeRails::Middleware, { mount: '/', timeout: 25 }.merge!(engine_params) do
      #map '/register**' => Comm::CommController
      #map '/publish**' => Comm::CommController
      #map '/subscribe**' => Comm::CommController
      map '/**' => Comm::ChannelsController
      map :default => :block
    end
  end
  ##Faye::Logging.log_level = :debug
  #Faye.logger = lambda { |m| puts m }
end
