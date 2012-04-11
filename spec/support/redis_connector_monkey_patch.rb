
# Dirty Monkey patch TODO fix sub/pub

class RedisConnector


  def self.sub
    @@subscriber = EM::Hiredis.connect
  end

  def self.pub
      @@publisher = EM::Hiredis.connect
  end
end
