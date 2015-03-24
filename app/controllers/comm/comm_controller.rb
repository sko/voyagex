module Comm
  class CommController < ::ActionController::Base  
    include ::AuthUtils

    def ping
      msg = { ping_key: params[:key] }
      render json: msg
    end

    # we don't subscribe the users to a channel but rather push to them (on their system-channel)
    # to subscribe on their own.
    # this way they also can have a dialog whether they are interested at all
    def register
      @user = User.find(params[:user_id])
      unless @user.comm_port.present?
        comm_port = CommPort.create(user: @user, channel_enc_key: enc_key, sys_channel_enc_key: enc_key)
        @user.comm_port = comm_port
      end

      if params[:subscribe_to_peers] == 'true'
        subscribe_user_to_peers @user
      end
      res = { user_id: @user.id,
              sys_channel_enc_key: @user.comm_port.sys_channel_enc_key,
              channel_enc_key: @user.comm_port.channel_enc_key }
      render json: res
    end

    def publish
binding.pry
      @user = User.find(params[:user_id])
    end

    def subscribe
binding.pry
      @user = User.find(params[:user_id])
    end

    private

    def subscribe_user_to_peers user
      peers_data = []
      User.joins(:comm_port).where('comm_ports.channel_enc_key != ?', user.comm_port.channel_enc_key).each do |peer|
        peers_data << { channel_enc_key: peer.comm_port.channel_enc_key, user: { id: peer.id, username: peer.username } }
        # notify peer about user
        msg = { type: :subscription_notification, peers: [channel_enc_key: user.comm_port.channel_enc_key, user: { id: user.id, username: user.username }] }
        Comm::ChannelsController.publish("/system#{PEER_CHANNEL_PREFIX}#{peer.comm_port.channel_enc_key}", msg)
      end
#      # notify user about peers - but user doesn't have key now
#      msg = { type: :subscription_notification, peers: peers_data }
#      Comm::ChannelsController.publish("/system#{PEER_CHANNEL_PREFIX}#{user.comm_port.channel_enc_key}", msg)
    end

  end
end
