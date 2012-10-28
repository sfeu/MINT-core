module MINT
  class AIOUTContinuous < AIOUT

    property :data, Integer, :default  => 0
    property :min, Integer,:default  => 0
    property :max, Integer,:default  => 100

    def getSCXML
      "#{File.dirname(__FILE__)}/aioutcontinuous.scxml"
    end

    PUBLISH_ATTRIBUTES += [:data]

    # functions called from scxml

    def data=(value)
      super  # use original method instead of accessing @ivar directly
      publish_update_new
    end

    def publish_update_new
      RedisConnector.redis.publish create_attribute_channel_name('data'), self.to_json(:only => self.class::PUBLISH_ATTRIBUTES)
    end


    def consume(attribute)
      @d = 0

      channel_name = create_attribute_channel_name(attribute)
      p "subscribed #{channel_name}"

      redis = RedisConnector.redis

      fiber = Fiber.current

      redis.pubsub.subscribe(channel_name) { |message|
        found=MultiJson.decode message

        if self.name.eql? found['name']
          if found['data']
            @d = found['data'].to_i
            @data = attribute_get(:data)

            process_event "move"
            restart_timeout(1,:halt)

            attribute_set(:data,@d)
            RedisConnector.redis.publish("out_channel:#{create_channel_w_name}:testuser",@data)
          end
        end
      }.callback {  fiber.resume}
      Fiber.yield
      @d
    end

    def halt(id)
      RedisConnector.sub.unsubscribe(self.class.create_channel_name+".#{id}")
    end
  end

end
