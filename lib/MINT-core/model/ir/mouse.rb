
module MINT
  class Mouse  < Pointer
    def initialize_statemachine
      if @statemachine.nil?
        parser = StatemachineParser.new(self)
        @statemachine = parser.build_from_scxml "#{File.dirname(__FILE__)}/mouse.scxml"

        @statemachine.reset

      end
    end

    def consume(id)
      subscription = self.class.create_channel_name+"."+id.to_s+":*"
      RedisConnector.sub.psubscribe(subscription) # TODO all users
      RedisConnector.sub.on(:pmessage) { |key, channel, message|
        if (key.eql? subscription)
          data = JSON.parse message

          if data["cmd"].eql? "pointer"
            x,y = data["data"]
            cache_coordinates x,y
            process_event("move") if not is_in? :moving
            restart_timeout
          else #button
            case data["data"]

              when "LEFT_PRESSED"
                process_event :press
              when "LEFT_RELEASED"
                process_event :release

            end

          end
        end
      }
    end

  end
end