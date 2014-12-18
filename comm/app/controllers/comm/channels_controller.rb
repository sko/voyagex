#require_dependency "comm/application_controller"

# curl -X POST http://192.168.1.4:3005/comm -H 'Content-Type: application/json' -d '{"channel":"/talk@rxbcin9nc","data":{"type":"chat", "text":"hello world"}}'
module Comm
  class ChannelsController < FayeRails::Controller

    # TODO
    # https://github.com/jamesotron/faye-rails#model-observers
    #observe Channel, :after_create do |new_channel|
    #  ChannelsController.publish('/widgets', new_widget.attributes)
    #end

    channel '/system**' do
      monitor :subscribe do
        ###### Client igt3vtbefo1rfmo5afi7wig5y7x3vx7 subscribed to /system@8jruy0aws.
        Rails.logger.debug "###### Client #{client_id} subscribed to #{channel}."
        subscription_enc_key = channel.match(/^\/system#{PEER_CHANNEL_PREFIX}([^\/]+)/)
        if subscription_enc_key.present?
          comm_setting = CommSetting.where(sys_channel_enc_key: subscription_enc_key[1]).first
          Rails.logger.debug "###### Found User #{comm_setting.user.id} for Client #{client_id}."
          comm_setting.update_attribute(:current_faye_client_id, client_id)

          # now that current_faye_client_id is set, the client can start to communicate
          # first it should register to it's own bidirectional channels
          msg = { type: :ready_notification, channel_enc_key: comm_setting.channel_enc_key }
          Comm::ChannelsController.publish("/system#{PEER_CHANNEL_PREFIX}#{subscription_enc_key[1]}", msg)
        end
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
      filter :in do
#[1] pry(#<FayeRails::Filter::DSL>)> message
#=> {"channel"=>"/meta/subscribe", "clientId"=>"dv2njyqmg7yvsy4q63143faf7m4iyby", "subscription"=>"/map_events", "id"=>"b"}
#[2] pry(#<FayeRails::Filter::DSL>)> 
###### Inbound message {"channel"=>"/meta/subscribe", "clientId"=>"adv6zxtpglnbcovod8ecbu4wwb2ykkm", "subscription"=>"/map_events@rxbcin9nc", "id"=>"4"}.
        block_msg = nil
        Rails.logger.debug "###### Inbound message #{message}."
        if message['channel'].match(/^\/meta\/subscribe/).present?
          subscription_enc_key = message['subscription'].match(/^.+?#{PEER_CHANNEL_PREFIX}([^\/]+)/)
          if subscription_enc_key.present?
            Rails.logger.debug "###### Inbound message: found subscription_enc_key '#{subscription_enc_key[1]}'"
            begin
              user_comm_setting = CommSetting.where(current_faye_client_id: message['clientId']).first
              if user_comm_setting.present?
                target = CommSetting.where(channel_enc_key: subscription_enc_key[1]).first
                # allow self-subscription so that others can communicate with me
                granted = target.present? &&
                          (target.current_faye_client_id == message['clientId'] ||
                           target.comm_peers.where(peer_id: user_comm_setting.user.id, granted_by_peer: true).present?)
                if granted
                  Rails.logger.debug "###### Inbound message: allow subscription on channel #{message['subscription']} for user #{user_comm_setting.user.id}"
                else
                  Rails.logger.debug "###### Inbound message: deny subscription on channel #{message['subscription']} for user #{user_comm_setting.user.id} because grant missing"
                  block_msg = 'grant required for subscription'
                end
              else
                Rails.logger.debug "###### Inbound message: deny subscription on channel #{message['subscription']} because user not signed in"
                block_msg = 'only subscribable for signed in users...'
              end
            rescue => e
              Rails.logger.error "###### #{e.message}"
            end
          end
        end
        if block_msg.nil?
          pass
        else
          block block_msg
        end
      end
      filter :out do
#[1] pry(#<FayeRails::Filter::DSL>)> message
#=> {"channel"=>"/map_events", "data"=>{"type"=>"click", "userId"=>"129", "lat"=>51.377941781653284, "lng"=>7.493147850036621}, "clientId"=>"l80967ybiset8aevchha4z6bmkqnced", "id"=>"r"}
#[2] pry(#<FayeRails::Filter::DSL>)> message.class
#=> Hash
        Rails.logger.debug "###### Outbound message #{message}."
        publish_data = message['data']
        if publish_data.present?
          case publish_data['type']
          when 'click'
            # could calculate it via Location.new(latitude: data['lat'], longitude: data['lng']).address
            # but maybe this is less expensive since reverse-geocode-lookup already done
            user = User.where(id: publish_data['userId']).first
            if user.present? && user.locations.present?
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
          # NO_SAVE_ON_ALL_CLICKS ls_u = user.locations_users.create(location: location)
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

    private

    def check_read_permission channel
      channel_enc_key_match = channel.match(/_\$(.+)/)
      if channel_enc_key_match.present?
        channel_enc_key = channel_enc_key_match[1]
      end
    end
  end
end
