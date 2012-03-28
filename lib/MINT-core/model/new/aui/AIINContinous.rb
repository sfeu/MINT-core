module MINT2


  class AIINContinous < AIIN

    property :data, Integer
    property :min, Integer,:default  => 0
    property :max, Integer,:default  => 100


    def initialize_statemachine
      if @statemachine.nil?
        parser = StatemachineParser.new(self)
        @statemachine = parser.build_from_scxml "#{File.dirname(__FILE__)}/AIINContinous.scxml"

        reset = @statemachine.reset

      end
    end

    # functions called from scxml

    def publish(attribute)
      channel_name =  create_attribute_channel_name(attribute)

      RedisConnector.sub.psubscribe('Element.AIO.AIIN.AIINContinous.'+self.name.to_s+":*") # TODO all users
      RedisConnector.sub.on(:pmessage) { |key, channel, message|
        if key.eql?  'Element.AIO.AIIN.AIINContinous.'+self.name.to_s+":*"
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
          RedisConnector.pub.publish channel_name,{:name=>self.name,:data => data}.to_json
        end
        end
      }

    end

    def halt(id)
      RedisConnector.sub.unsubscribe(self.class.create_channel_name+".#{id}")
    end
  end

end
