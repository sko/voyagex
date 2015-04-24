module Comm
  class Adapter
  
    FAYE_CLIENT = Faye::Client.new(::FAYE_URL)

    def publish channel, enc_key, msg, user
      channel = "#{channel}#{PEER_CHANNEL_PREFIX}#{enc_key}" unless USE_GLOBAL_SUBSCRIBE
      #Comm::ChannelsController.publish("/#{channel}", msg)
      EM.run {
        num_cbs = 0

        publication = Adapter::FAYE_CLIENT.publish("/#{channel}", msg)
        publication.callback { Rails.logger.debug("sent #{channel} to user: user = #{user.id} / #{user.username}"); EM.stop if (num_cbs += 1) == 2 }
        publication.errback {|error| Rails.logger.error("#{channel}to user: user = #{user.id} / #{user.username} - error: #{error.message}"); EM.stop if (num_cbs += 1) == 2 }
      }
    end

  end
end
