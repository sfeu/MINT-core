module ConnectionHelper
  def connect(url = nil, &blk)
    em do
      redis = EventMachine::Hiredis.connect(url)
      redis.flushall
      blk.call(redis)
      EM.stop_event_loop
    end
  end
end
