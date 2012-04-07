module MINT
  class AIOUTContinous < AIOUT

    property :data, Integer
    property :min, Integer,:default  => 0
    property :max, Integer,:default  => 100

    def initialize_statemachine
      if @statemachine.nil?
        parser = StatemachineParser.new(self)
        @statemachine = parser.build_from_scxml "#{File.dirname(__FILE__)}/aioutcontinous.scxml"

        @statemachine.reset

      end
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
      channel_name = create_attribute_channel_name(attribute)
      RedisConnector.sub.subscribe(channel_name)
      RedisConnector.sub.on(:message) { |channel, message|
        if channel.eql? channel_name

          found=JSON.parse message

          if self.name.eql? found['name']
            if found['data']
              value = found['data'].to_i


              d = attribute_get(:data)
              if d
                if value > d and not (is_in?(:progressing) or is_in?(:max))# state comparison just for performance
                  process_event("progress")
                elsif value  < d and not (is_in?(:regressing) or is_in?(:min))
                  process_event("regress")
                end
              else
                #  @statemachine.process_event("progress") # default progress TODO improve default handling for first data
              end
              attribute_set(:data,value)
              RedisConnector.pub.publish("ss:channels",{:event=>self.class.create_channel_name+".#{self.name}",:params=>{:name=>self.name,:data=>value },:destinations=>["user:testuser"]}.to_json)
            end
          end
        end
      }



    end

    def halt(id)
      RedisConnector.sub.unsubscribe(self.class.create_channel_name+".#{id}")
    end
  end

end
