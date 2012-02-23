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

      @@subscriber.subscribe(self.class.create_channel_name+".#{id}")
      @@subscriber.on(:message) { |channel, message|

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

      }


    end

    def halt(id)
      @@subscriber.unsubscribe(self.class.create_channel_name+".#{id}")
    end
  end

end
