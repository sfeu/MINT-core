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

      RedisConnector.sub.subscribe(self.class.create_channel_name)
      RedisConnector.sub.on(:message) { |channel, message|
        if channel.eql? self.class.create_channel_name

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
              RedisConnector.pub.publish("ss:channels",{:event=>self.class.create_channel_name+".#{self.name}",:params=>{:data=>value },:destinations=>["user:test"]}.to_json)
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
