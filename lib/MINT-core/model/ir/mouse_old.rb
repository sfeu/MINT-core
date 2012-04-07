require "eventmachine"
module MINTo

  class MouseMode < Interactor
    def initialize_statemachine
      if @statemachine.blank?
        @statemachine = Statemachine.build do
          trans :selecting,:drag, :dragging
          trans :dragging, :select, :selecting
        end
      end
    end
  end

  class Mouse  < Pointer

      class CoordinateTracker
        include EventMachine::Deferrable
        def initialize(mouse)
          @mouse = mouse
          p "handling juggernait"
          Redis.new.subscribe("juggernaut") do |on|
            on.mon.message do |msg|
              r = msg.parseJSON
              if (r["channels"].eql? "pointer")
                @x,@y = r["data"].split
              end
            end
          end
        end
        def save(state)
          @mouse.x=@x
          @mouse.y=@y
          @mouse.process_event(state)
          p "stopped"
        end
      end

#    property :x, Integer, :default  => -1
#    property :y, Integer, :default  => -1
    property :z, Integer, :default  => 0

    def cache_coordinates(x,y)
      @x = x
      @y = y
    end

    def initialize_statemachine
      if @statemachine.blank?

        @pointer_timer = nil
        @wheel_timer = nil

        @statemachine = Statemachine.build do

          trans :disconnected,:connect, :connected
          trans :connected, :disconnect, :disconnected

          superstate :connected do
            parallel :p do
              statemachine :s1 do
                superstate :pointer do
                  on_entry :start_coordinates_tracker
                  on_exit :stop_coordinates_tracker


                  trans :stopped, :move, :moving
                  trans :moving,:move, :moving
                  trans :moving,:stop,:stopped

                  state :moving do
                    on_entry :start_timeout_pointer # TODO no support for varibles in on_entry on_exit
                    on_exit :stop_timeout_pointer
                  end
                end
              end
              statemachine :s2 do
                superstate :right_button do # TODO we still not have name spaces :-(
                  trans :right_released, :right_press, :right_pressed
                  trans :right_pressed, :right_release, :right_released
                end
              end
              statemachine :s3 do
                superstate :left_button do # TODO we still not have name spaces :-(
                  trans :left_released, :left_press, :left_pressed
                  trans :left_pressed, :left_release, :left_released
                end
              end
              statemachine :s4 do
                superstate :middle_button do # TODO we still not have name spaces :-(
                  trans :middle_released, :middle_press, :middle_pressed
                  trans :middle_pressed, :middle_release, :middle_released
                end
              end
              statemachine :s5 do
                superstate :wheel do
                  trans :wheel_stopped,:regress, :regressing
                  trans :wheel_stopped,:progress, :progressing

                  trans :regressing, :regress, :regressing
                  trans :regressing, :stop_wheel, :wheel_stopped
                  trans :regressing, :progress, :progressing

                  trans :progressing, :progress, :progressing
                  trans :progressing, :stop_wheel, :wheel_stopped
                  trans :progressing, :regress, :regressing

                  state :regressing do
                    on_entry :start_timeout_wheel
                    on_exit :stop_timeout_wheel
                  end
                  state :progressing do
                    on_entry :start_timeout_wheel
                    on_exit :stop_timeout_wheel
                  end
                end
              end
            end
          end
        end
      end

      def start_timeout_wheel
        if not @wheel_timer
          @wheel_timer = EventMachine::Timer.new(0.3) do
            process_event("stop_wheel")
          end
        else
          puts "wheel timer already started!!!"
        end
      end

      def stop_timeout_wheel
        stop_timeout(@wheel_timer)
      end

      def start_timeout_pointer
#        @tracker  = CoordinateTracker.new(self)
#        @tracker.callback do |x|
#          @tracker.save(state)
#        end

        if not @pointer_timer
          @pointer_timer = EventMachine::Timer.new(0.3) do
            @mouse.x=@x
          @mouse.y=@y
          @mouse.process_event("stop")

#            @tracker.set_deferred_status :succeeded, "stop"
          end
        else
          puts "pointer timer already started!!!"
        end
      end


      def stop_timeout_pointer
        stop_timeout(@pointer_timer)
      end

      def stop_timeout(timer)
        if timer
          timer.cancel
          timer = nil
        end
      end
    end

  end

end