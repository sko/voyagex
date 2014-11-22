#require_dependency "comm/application_controller"

# curl -X POST http://192.168.1.4:3005/comm -H 'Content-Type: application/json' -d '{"channel":"/talk","data":{"hello":"world"}}'
module Comm
  class ChannelsController < FayeRails::Controller

    # TODO
    # https://github.com/jamesotron/faye-rails#model-observers
    #observe Channel, :after_create do |new_channel|
    #  ChannelsController.publish('/widgets', new_widget.attributes)
    #end

    channel '/system**' do
      monitor :subscribe do
        Rails.logger.debug "###### Client #{client_id} subscribed to #{channel}."
      end
      monitor :unsubscribe do
        Rails.logger.debug "###### Client #{client_id} unsubscribed from #{channel}."
      end
      monitor :publish do
        Rails.logger.debug "###### Client #{client_id} published #{data.inspect} to #{channel}."
      end
    end

    channel '/talk**' do
      monitor :subscribe do
        Rails.logger.debug "###### Client #{client_id} subscribed to #{channel}."
      end
      monitor :unsubscribe do
        Rails.logger.debug "###### Client #{client_id} unsubscribed from #{channel}."
      end
      monitor :publish do
        Rails.logger.debug "###### Client #{client_id} published #{data.inspect} to #{channel}."
        # 1: here we could implement dynamic groups that should not know about channel-id so they
        #    can be removed any-time
        # 2: alternatively other users could subscribe by receiving the key
        # FIXME 2 is better - a session-key can be used
        channel_enc_key_match = channel.match(/_\$(.+)/)
        if channel_enc_key_match.present?
          channel_enc_key = channel_enc_key_match[1]
        end
      end
    end

    channel '/map_events**' do
      filter :out do
#[1] pry(#<FayeRails::Filter::DSL>)> message
#=> {"channel"=>"/map_events", "data"=>{"type"=>"click", "userId"=>"129", "lat"=>51.377941781653284, "lng"=>7.493147850036621}, "clientId"=>"l80967ybiset8aevchha4z6bmkqnced", "id"=>"r"}
#[2] pry(#<FayeRails::Filter::DSL>)> message.class
#=> Hash
        Rails.logger.debug "###### Inbound message #{message}."
        publish_data = message['data']
        if publish_data.present?
          case publish_data['type']
          when 'click'
            # could calculate it via Location.new(latitude: data['lat'], longitude: data['lng']).address
            # but maybe this is less expensive since reverse-geocode-lookup already done
            user = User.where(id: publish_data['userId']).first
            if user.present?
              location = user.locations.last
              Rails.logger.debug "###### providing reverse-geocoding-service: #{location.address}"
              publish_data['address'] = location.address
            end
          end
        end
        pass
      end
      monitor :subscribe do
        Rails.logger.debug "###### Client #{client_id} subscribed to #{channel}."
      end
      monitor :unsubscribe do
        Rails.logger.debug "###### Client #{client_id} unsubscribed from #{channel}."
      end
      monitor :publish do
        Rails.logger.debug "###### Client #{client_id} published #{data.inspect} to #{channel}."
        case data['type']
        when 'click'
          user = User.where(id: data['userId']).first
          location = Location.new(latitude: data['lat'], longitude: data['lng'])
          # TODO maybe select existing location if exists instead of creating new - l.nearbys(5)
          ls_u = user.locations_users.create(location: location)
          # provide reverse lookup
          unless data['address'].present?
            Rails.logger.debug "###### providing reverse-geocoding-service: #{location.address}"
            data['address'] = location.address
          end
        end
      end
    end

    channel '/uploads**' do
      monitor :subscribe do
        Rails.logger.debug "###### Client #{client_id} subscribed to #{channel}."
      end
      monitor :unsubscribe do
        Rails.logger.debug "###### Client #{client_id} unsubscribed from #{channel}."
      end
      monitor :publish do
        Rails.logger.debug "###### Client #{client_id} published #{data.inspect} to #{channel}."
      end
    end

  end
end
