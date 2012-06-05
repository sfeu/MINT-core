
module ConnectionHelper
  def connect(wait = false, &blk)

    em do
      redis =EM::Hiredis.connect
      redis.callback{
        redis.flushall.callback {
          blk.call(redis)
          EM.stop_event_loop if not wait
          EM.add_timer(3) {
                raise "Timeout. Test failed after waiting 3 seconds for an event that not occurred."
                done

              }
        }
      }
    end
  end
end
