module Comm
  class Adapter

    def publish channel, enc_key, msg, user, prio = :normal
      if enc_key.present? && (!USE_GLOBAL_SUBSCRIBE)
        channel = "/#{channel}#{PEER_CHANNEL_PREFIX}#{enc_key}"
      else
        channel = "/#{channel}"
      end
      if (prio != :high) && (![:development].include?(Rails.env.to_sym))
        Resque.enqueue Publisher, { action: 'publish',
                                    channel: channel,
                                    msg: msg,
                                    user_id: user.id } 
      else
        msgs_data = [
                      { channel: channel,
                        msg: msg,
                        user_id: user.id }
                    ]
        Publisher.new.publish msgs_data, false
      end
    end

  end
end
