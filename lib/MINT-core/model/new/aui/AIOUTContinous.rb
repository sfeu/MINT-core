module MINT2


  class AIOUTContinous < AIOUT

    property :data, Integer

    def initialize_statemachine
      if @statemachine.nil?
        parser = StatemachineParser.new(self)
        @statemachine = parser.build_from_scxml "#{File.dirname(__FILE__)}/AIOUTContinous.scxml"

        @statemachine.reset

      end
    end

    # functions called from scxml



    def consume(id)

      RedisConnector.sub.subscribe(self.class.create_channel_name+".#{id}")
      RedisConnector.sub.on(:message) { |channel, message|

        d = attribute_get(:data)
        if d
          if message.to_i > d and not (is_in?(:progressing) or is_in?(:max))# state comparison just for performance
            process_event("progress")
          elsif message.to_i < d and not (is_in?(:regressing) or is_in?(:min))
            process_event("regress")
          end
        else
          #  @statemachine.process_event("progress") # default progress TODO improve default handling for first data
        end
        attribute_set(:data,message.to_i)
        RedisConnector.pub.publish("ss:channels",{:event=>self.class.create_channel_name+".#{id}",:params=>{:data=>message.to_i},:destinations=>["user:test"]}.to_json)
      }


    end

    def halt(id)
      RedisConnector.sub.unsubscribe(self.class.create_channel_name+".#{id}")
    end
  end

end
