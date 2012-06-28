class RedisConnector

  def self.redis

    @@redis ||= EventMachine::Hiredis.connect
  end

  def self.reset
    @@redis =nil
  end

end