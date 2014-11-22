module Comm
  class CommController < ActionController::Base  

    # we don't subscribe the users to a channel but rather push to them (on their channel) to subscribe on their own.
    # this way they also can have a dialog whether they are interested at all
    def register
      @user = User.find(params[:user_id])
      unless @user.comm_setting.present?
        src = ('a'..'z').to_a + (0..9).to_a
        code_length = 8
        enc_key = (0..code_length).map { src[rand(36)] }.join
        comm_setting = CommSetting.create(user: @user, channel_enc_key: enc_key)
        @user.comm_setting = comm_setting
      end
      subscribe_user_to_peers @user
      res = { user_id: @user.id, channel_enc_key: @user.comm_setting.channel_enc_key }
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
      User.joins(:comm_setting).where('comm_settings.channel_enc_key != ?', user.comm_setting.channel_enc_key).each do |u|
        #user.comm_setting.comm_peers.create(peer: u) unless user.comm_setting.comm_peers.include? u
        #u.comm_setting.comm_peers.create(peer: user) unless u.comm_setting.comm_peers.include? user
        peers_data << { channel_enc_key: u.comm_setting.channel_enc_key, user: { id: u.id, username: u.username } }
        # notify peer about user
        msg = { type: :subscription_notification, peers: [channel_enc_key: user.comm_setting.channel_enc_key, user: { id: user.id, username: user.username }] }
        Comm::ChannelsController.publish("/system#{PEER_CHANNEL_PREFIX}#{u.comm_setting.channel_enc_key}", msg)
      end
      # notify user about peers
      msg = { type: :subscription_notification, peers: peers_data }
      Comm::ChannelsController.publish("/system#{PEER_CHANNEL_PREFIX}#{user.comm_setting.channel_enc_key}", msg)
    end

  end
end
