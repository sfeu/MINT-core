
module MINT
  class Mouse  < Pointer

    def getSCXML
      "#{File.dirname(__FILE__)}/mouse.scxml"
    end

    def consume(id)
      subscription = "data:"+self.class.create_channel_name+"."+id.to_s+":*"

      redis = RedisConnector.redis

      redis.pubsub.psubscribe(subscription) { |key,message|

       # if (key.eql? subscription)
          data = MultiJson.decode message

          if data["cmd"].eql? "pointer"
            x,y = data["data"]
            cache_coordinates x,y
            process_event("move") if not is_in? :moving
            restart_timeout
          else #button
            case data["data"]

              when "LEFT_PRESSED"
                process_event :press_left
              when "LEFT_RELEASED"
                process_event :release_left
              when "RIGHT_PRESSED"
                process_event :press_right
              when "RIGHT_RELEASED"
                process_event :release_right

            end

          end
       # end
      }
    end

  end
end