#require_dependency "comm/application_controller"

# curl -X POST http://192.168.1.4:3005/comm -H 'Content-Type: application/json' -d '{"channel":"/talk@rxbcin9nc","data":{"type":"chat", "text":"hello world"}}'
include ::GeoUtils
include ::ApplicationHelper
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
          #
          # when a client subscribes he gets a ready-notification
          #
          begin
            comm_port = CommPort.where(sys_channel_enc_key: subscription_enc_key[1]).first
            Rails.logger.debug "###### Found User #{comm_port.user.id} for Client #{client_id}. comm_port.unsubscribe_ts = #{comm_port.unsubscribe_ts}"
            if comm_port.unsubscribe_ts.present?
              msg = { type: :unsubscribed_notification, old_client_id: comm_port.current_faye_client_id, seconds_ago: ((DateTime.now - comm_port.unsubscribe_ts.to_datetime) * 24 * 60 * 60).to_i }
              Comm::ChannelsController.publish(channel, msg)
              comm_port.update_attributes(current_faye_client_id: client_id, unsubscribe_ts: nil)
            else
              comm_port.update_attribute(:current_faye_client_id, client_id)
            end
            # now that current_faye_client_id is set, the client can start to communicate
            # first it should register to it's own bidirectional channels
            msg = { type: :ready_notification, channel_enc_key: comm_port.channel_enc_key }
           #Comm::ChannelsController.publish("/system#{PEER_CHANNEL_PREFIX}#{subscription_enc_key[1]}", msg)
            Comm::ChannelsController.publish(channel, msg)
          rescue => e
            Rails.logger.error "!!!!!! #{e.message}"
          end
        end
      end
      monitor :unsubscribe do
        Rails.logger.debug "###### Client #{client_id} unsubscribed from #{channel}."
###### Client 0wsoszcovhq9k2y9xhpax15wvam4jld unsubscribed from /system@gyimlwqrh.
        subscription_enc_key = channel.match(/^\/system#{PEER_CHANNEL_PREFIX}([^\/]+)/)
        if subscription_enc_key.present?
          begin
            # store info and send to client on next subscription
            # since unsubscribed client would'n receive it here
            comm_port = CommPort.where(sys_channel_enc_key: subscription_enc_key[1]).first
            Rails.logger.debug "###### Found User #{comm_port.user.id} for Client #{client_id}."
            comm_port.update_attribute(:unsubscribe_ts, DateTime.now)
          rescue => e
            Rails.logger.error "!!!!!! #{e.message}"
          end
        end
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
        Rails.logger.debug "###### Inbound message #{message}. (self: #{self.hash} / #{self.object_id})"
        if message['channel'].match(/^\/meta\/subscribe/).present?
          block_msg = ChannelsController::check_subscribe_permission message
          # subscription_enc_key = message['subscription'].match(/^.+?#{PEER_CHANNEL_PREFIX}([^\/]+)/)
          # if subscription_enc_key.present?
          #   Rails.logger.debug "###### Inbound message: found subscription_enc_key '#{subscription_enc_key[1]}'"
          #   begin
          #     user_comm_port = CommPort.where(current_faye_client_id: message['clientId']).first
          #     if user_comm_port.present?
          #       target = CommPort.where(channel_enc_key: subscription_enc_key[1]).first
          #       # allow self-subscription so that others can communicate with me
          #       granted = target.present? &&
          #                 (target.current_faye_client_id == message['clientId'] ||
          #                  target.comm_peers.where(peer_id: user_comm_port.user.id, granted_by_peer: true).present?)
          #       if granted
          #         Rails.logger.debug "###### Inbound message: allow subscription on channel #{message['subscription']} for user #{user_comm_port.user.id}"
          #       else
          #         Rails.logger.debug "###### Inbound message: deny subscription on channel #{message['subscription']} for user #{user_comm_port.user.id} because grant missing"
          #         block_msg = 'grant required for subscription'
          #       end
          #     else
          #       Rails.logger.debug "###### Inbound message: deny subscription on channel #{message['subscription']} because user not signed in"
          #       block_msg = 'only subscribable for signed in users...'
          #     end
          #   rescue => e
          #     Rails.logger.error "!!!!!! #{e.message}"
          #   end
          # end
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
          begin
            case publish_data['type']
            when 'click'
              unless publish_data['address'].present?
                begin
                  location = Location.new(latitude: publish_data['lat'], longitude: publish_data['lng'])
                  location = nearby_location location, 10
                  if location.persisted?
                    address = shorten_address location
                    publish_data['locationId'] = location.id
                  else
                    geo = Geocoder.search([publish_data['lat'], publish_data['lng']])
                    address = geo[0].address
                    parts = address.split(',')
                    if parts.size >= 3
                      address = parts.drop([parts.size - 2, 2].min).join(',').strip
                    end
                  end
                  Rails.logger.debug "###### providing reverse-geocoding-service: #{address}"
                  publish_data['address'] = address
                rescue => e
                  Rails.logger.error "!!!!!! #{e.message}"
                end
              end
            end
          rescue => e
            Rails.logger.error "!!!!!! #{e.message}"
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
        begin
          case data['type']
          when 'click'
            user = User.where(id: data['userId']).first
            location = nearby_location Location.new(latitude: data['lat'], longitude: data['lng']), 10
            if location.persisted?
              user.snapshot.location = location
              user.snapshot.lat = nil
              user.snapshot.lng = nil
              user.snapshot.address = nil
            else
              user.snapshot.location = nil
              user.snapshot.lat = location.latitude
              user.snapshot.lng = location.longitude
              user.snapshot.address = shorten_address location, true
            end
            user.snapshot.save!
          end
        rescue => e
          Rails.logger.error "!!!!!! #{e.message}"
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
    
    channel '/radar**' do
      filter :in do
        block_msg = nil
        Rails.logger.debug "###### Inbound message #{message}. (self: #{self.hash} / #{self.object_id})"
        if message['channel'].match(/^\/meta\/subscribe/).present?
          block_msg = ChannelsController::check_subscribe_permission message
        end
        if block_msg.nil?
          pass
        else
          block block_msg
        end
      end
      monitor :subscribe do
        Rails.logger.debug "###### Client #{client_id} subscribed to #{channel}."
      end
      monitor :unsubscribe do
        Rails.logger.debug "###### Client #{client_id} unsubscribed from #{channel}."
      end
      monitor :publish do
        Rails.logger.debug "###### Client #{client_id} published #{data.inspect} to #{channel}."
        # begin
        #   case data['type']
        #   when 'move'
        #     user = User.where(id: data['userId']).first
        #     location = nearby_location Location.new(latitude: data['lat'], longitude: data['lng']), 10
        #     if location.persisted?
        #       user.snapshot.location = location
        #       user.snapshot.lat = nil
        #       user.snapshot.lng = nil
        #       user.snapshot.address = nil
        #     else
        #       user.snapshot.location = nil
        #       user.snapshot.lat = location.latitude
        #       user.snapshot.lng = location.longitude
        #       user.snapshot.address = shorten_address location, true
        #     end
        #     user.snapshot.save!
        #   end
        # rescue => e
        #   Rails.logger.error "!!!!!! #{e.message}"
        # end
      end
    end

    private

    def self.check_subscribe_permission message
      block_msg = nil
      subscription_enc_key = message['subscription'].match(/^.+?#{PEER_CHANNEL_PREFIX}([^\/]+)/)
      if subscription_enc_key.present?
        Rails.logger.debug "###### Inbound message: found subscription_enc_key '#{subscription_enc_key[1]}'"
        begin
          user_comm_port = CommPort.where(current_faye_client_id: message['clientId']).first
          if user_comm_port.present?
            target = CommPort.where(channel_enc_key: subscription_enc_key[1]).first
            # allow self-subscription so that others can communicate with me
            granted = target.present? &&
                      (target.current_faye_client_id == message['clientId'] ||
                       target.comm_peers.where(peer_id: user_comm_port.user.id, granted_by_peer: true).present?)
            if granted
              Rails.logger.debug "###### Inbound message: allow subscription on channel #{message['subscription']} for user #{user_comm_port.user.id}"
            else
              Rails.logger.debug "###### Inbound message: deny subscription on channel #{message['subscription']} for user #{user_comm_port.user.id} because grant missing"
              block_msg = 'grant required for subscription'
            end
          else
            Rails.logger.debug "###### Inbound message: deny subscription on channel #{message['subscription']} because user not signed in"
            block_msg = 'only subscribable for signed in users...'
          end
        rescue => e
          Rails.logger.error "!!!!!! #{e.message}"
        end
      end
      block_msg
    end

    def check_read_permission channel
      channel_enc_key_match = channel.match(/_\$(.+)/)
      if channel_enc_key_match.present?
        channel_enc_key = channel_enc_key_match[1]
      end
    end
  end
end
