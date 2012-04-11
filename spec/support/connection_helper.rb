
module ConnectionHelper
  def connect(wait = false, &blk)

    em do
      redis =EM::Hiredis.connect
      redis.callback{
        redis.flushall.callback {
          blk.call(redis)
          EM.stop_event_loop if not wait
        }
      }
    end
  end
end
