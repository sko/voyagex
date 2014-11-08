#require_dependency "comm/application_controller"

# curl -X POST http://192.168.1.4:3005/comm -H 'Content-Type: application/json' -d '{"channel":"/talk","data":{"hello":"world"}}'
module Comm
  class ChannelsController < FayeRails::Controller

    channel '/talk' do
      monitor :subscribe do
        puts "Client #{client_id} subscribed to #{channel}."
      end
      monitor :unsubscribe do
        puts "Client #{client_id} unsubscribed from #{channel}."
      end
      monitor :publish do
        puts "Client #{client_id} published #{data.inspect} to #{channel}."
      end
    end

    channel '/map_events' do
      monitor :subscribe do
        puts "Client #{client_id} subscribed to #{channel}."
      end
      monitor :unsubscribe do
        puts "Client #{client_id} unsubscribed from #{channel}."
      end
      monitor :publish do
        puts "Client #{client_id} published #{data.inspect} to #{channel}."
      end
    end

  end
end
