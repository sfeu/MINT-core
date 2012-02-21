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

    def move(id)
      @@redis.subscribe(self.class.create_channel_name+".#{id}") do |on|
        on.message do |channel, message|

          d = attribute_get(:data)
          if d
            if message.to_i > d and %w(progressing max).include?(state)     # state comparison just for performance
              @statemachine.process_event("progress")
            elsif message.to_i < d and %w(regressing min).include?(state)
              @statemachine.process_event("regress")
            end
            else
              @statemachine.process_event("progress") # default progress TODO improve default handling for first data
            end
            attribute_set(:data,message.to_i)
        end
      end
    end

    def halt(id)
      @@redis.unsubscribe(self.class.create_channel_name+".#{id}")
    end
  end

end
