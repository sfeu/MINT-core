module MINT2


  class AIINContinous < AIIN

    property :data, Integer
    property :min, Integer,:default  => 0
    property :max, Integer,:default  => 100


    def initialize_statemachine
      if @statemachine.nil?
        parser = StatemachineParser.new(self)
        @statemachine = parser.build_from_scxml "#{File.dirname(__FILE__)}/AIINContinous.scxml"

        @statemachine.reset

      end
    end

    # functions called from scxml

    def publish(id)
      @publish = id.to_s
    end

    def stop_publish(id)
      @publish = nil
    end

    def consume(id)
      RedisConnector.sub.psubscribe('Element.AIO.AIIN.AIINContinous.'+id.to_s+":*") # TODO all users
      RedisConnector.sub.on(:pmessage) { |key, channel, message|

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
          RedisConnector.pub.publish "Element.AIO.AIIN.AIINContinous",{:name=>self.name,:data => data}.to_json if @publish
        end
      }

    end

    def halt(id)
      RedisConnector.sub.unsubscribe(self.class.create_channel_name+".#{id}")
    end
  end

end
