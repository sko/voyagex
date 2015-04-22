module Comm
  class Manager

    def publish channel, enc_key, msg
      #channelPath = channel
      #channel_path += "#{PEER_CHANNEL_PREFIX}#{enc_key}" unless USE_GLOBAL_SUBSCRIBE
      Comm::ChannelsController.publish("/#{channel}#{PEER_CHANNEL_PREFIX}#{enc_key}", msg)
    end

  end
end
