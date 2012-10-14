module MINT


  class AIINContinuous < AIIN

    property :data, Integer
    property :min, Integer,:default  => 0
    property :max, Integer,:default  => 100

    def getSCXML
      "#{File.dirname(__FILE__)}/aiincontinuous.scxml"
    end

    # functions called from scxml

    def publish(attribute)
      channel_name =  create_attribute_channel_name(attribute)

      redis = RedisConnector.redis

      fiber = Fiber.current

      redis.pubsub.psubscribe('in_channel:Interactor.AIO.AIIN.AIINContinuous.'+self.name.to_s+":*") { |key,message|
        sync_states
        if message.eql? "stop"
          process_event("halt")
        else
          d = attribute_get(:data)

          if d
            if message.to_i > d and not (is_in?(:progressing) or is_in?(:max))# state comparison just for performance
              process_event("progress")
            elsif message.to_i < d and not (is_in?(:regressing) or is_in?(:min))
              process_event("regress")
            end
          else
            #  @statemachine.process_event("progress") # default progress TODO improve default handling for first data
            process_event("progress")
          end

          attribute_set(:data,message.to_i)
          RedisConnector.redis.publish channel_name,MultiJson.encode({:name=>self.name,:data => data})
        end

      }.callback {  fiber.resume}
      Fiber.yield


    end

    def halt(id)
      RedisConnector.sub.unsubscribe(self.class.create_channel_name+".#{id}")
    end
  end

end
