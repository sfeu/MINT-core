class RedisConnector

  def self.redis

    @@redis ||= EventMachine::Hiredis.connect
  end

  def self.sync_redis
    @@sync_redis ||= Redis.new
  end

  def self.reset
    @@redis =nil
  end

end