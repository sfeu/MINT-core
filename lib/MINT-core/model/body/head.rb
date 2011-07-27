module MINT
  class Head < Element
    #property :angle, Integer, :default  => -1
    #property :distance, Integer, :default  => -1

    def initialize_statemachine
      if @statemachine.blank?
        @statemachine = Statemachine.build do

          trans :disconnected,:connect, :connected
          trans :connected, :disconnect, :disconnected

          superstate :connected do
            trans :centered, :left, :moving_left
            trans :centered,:right,:moving_right
            superstate :moving do
                on_entry :start_publish_angle
                on_exit :stop_publish_angle
              trans :moving_left,:center, :centered
              trans :moving_right,:center, :centered
            end
          end
        end
      end
    end

    def angle=(angle)
       if @publish_angle
        Juggernaut.publish("head/angle", "#{angle}")
       end
    end

    def start_publish_angle
      @publish_angle=true
    end

    def stop_publish_angle
      @publish_angle=false
    end
  end
end