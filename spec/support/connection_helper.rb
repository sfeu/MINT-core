$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
require "MINT-core/connector/redis_connector"


module ConnectionHelper
  def connect(wait = false, timeout = 10, &blk)
    em(timeout) do
      RedisConnector.reset
      redis = RedisConnector.redis

        redis.flushall.callback {
          blk.call(redis)
          EM.stop_event_loop if not wait
        }

    end
  end
end
