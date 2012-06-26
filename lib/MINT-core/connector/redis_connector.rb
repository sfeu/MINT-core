class RedisConnector

  def self.redis

    @@redis ||= EventMachine::Hiredis.connect
  end


end