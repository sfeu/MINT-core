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
       RedisConnector.pub.publish create_channel_w_name, self.to_json(:only => self.class::PUBLISH_ATTRIBUTES)
    end


    def consume(attribute)
      @d = 0

      channel_name = create_attribute_channel_name(attribute)
      p "subscribed #{channel_name}"
      r = RedisConnector.sub
      r.subscribe(channel_name)

      r.on(:message) { |channel, message|
        if channel.eql? channel_name

          found=JSON.parse message

          if self.name.eql? found['name']
            if found['data']
              @d = found['data'].to_i
              @data = attribute_get(:data)

              process_event "move"

              #if d
              #  if value > d and not (is_in?(:progressing) or is_in?(:max))# state comparison just for performance
              #    process_event("move")
              #  elsif value  < d and not (is_in?(:regressing) or is_in?(:min))
              #    process_event("move")
              #  end
              #else
              #  #  @statemachine.process_event("progress") # default progress TODO improve default handling for first data
              #end
              attribute_set(:data,@d)
              RedisConnector.pub.publish("ss:channels",{:event=>self.class.create_channel_name+".#{self.name}",:params=>{:name=>self.name,:data=>@d },:destinations=>["user:testuser"]}.to_json)
            end
          end
        end
      }


      @d
    end

    def halt(id)
      RedisConnector.sub.unsubscribe(self.class.create_channel_name+".#{id}")
    end
  end

end
