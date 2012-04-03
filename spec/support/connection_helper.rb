module ConnectionHelper
  def connect(wait = false, &blk)
    em do
      redis = EventMachine::Hiredis.connect
      redis.flushall
      blk.call(redis)
      EM.stop_event_loop if not wait
    end
  end
end
