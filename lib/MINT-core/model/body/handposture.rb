module MINT
  class HandPosture < Interactor
    attr_accessor :connection
    def start_ticker(timeout)
      @timer = EM::PeriodicTimer.new(timeout) {
        self.process_event :tick
      }
    end

    def stop_ticker
      @timer.cancel
    end


    def start(host ="0.0.0.0", port=4444)
      EventMachine::start_server host, port, StatefulProtocol do |conn|
        @connection = conn

        conn.hand_gesture = self
        puts "connection..."
        self.process_event :connect
      end
      puts "Started hand posture control server on #{host}:#{port}"
    end

    class StatefulProtocol < EventMachine::Connection
      include EM::Protocols::LineText2
      attr_accessor :hand_gesture
      attr_accessor :speed

      def initialize
        super()
        @zoom_level=0

        #tracks distance for one handed interaction
        @distance_level = 0

        # calibrates the distance when previous or next gesture is issued
        @calibrated_distance = 0
        # threshold for distance tracking
        @distance_threshold = 1
        #    @factor = 25 was working well for zooming gesture
        @factor = 150

        # the timeout value range and stepping
        @min_command_timeout = 0.4
        @max_command_timeout = 1.6
        @command_timeout_step = 0.1
        @drop_counter=0
      end

      def unbind
        p "disconnect"
        @hand_gesture.process_event :disconnect
      end
      def receive_line(data)
        begin
          case data
            when /ZOOM-\d+/
              d = /ZOOM-(\d+)/.match(data)[1].to_i
              if (@zoom_level == 0)
                @zoom_level = d
                return
              end
              if (d>(@zoom_level+@factor))
                @zoom_level = d
                @hand_gesture.process_event(:widen,d)
              elsif (d<(@zoom_level-@factor))
                @hand_gesture.process_event(:narrow,d)
                @zoom_level = d
              end
            when /AREA-\d+/
              if @drop_counter >0
                @drop_counter =0
                return
              end
              @drop_counter +=1

              r = /AREA-(\d+)/.match(data)[1].to_i
              @distance_level = Math.sqrt(r).to_i # transformation to a linear function
              #puts "received #{@distance_level} calibration: #{@calibrated_distance}"
              if @calibrated_distance == 0 # the first area after a next of prev gesture is uesed for calibration
                return
              end
              if (@calibrated_distance-@distance_level)>(@distance_threshold)
                #p "FARER"
                @calibrated_distance= @distance_level
                @hand_gesture.process_event(:farer)
                return
              end
              if (@distance_level-@calibrated_distance)>(@distance_threshold)
                #p "CLOOOOSER"
                @calibrated_distance= @distance_level
                @hand_gesture.process_event(:closer)
                return
              end
            when /PREV/
              @hand_gesture.process_event(:prev_gesture)
              @calibrated_distance = @distance_level
            when /NEXT/
              @hand_gesture.process_event(:next_gesture)
              @calibrated_distance = @distance_level
            when /CONFIRM/
              @hand_gesture.process_event(:confirm)
            when /SELECT/
              @hand_gesture.process_event(:select)
            when /HANDS-2/
              @zoom_level = 0
              @hand_gesture.process_event(:two_hands)
            when /HANDS-1/
              @hand_gesture.process_event(:one_hand)
              puts @hand_gesture.states
            when /HANDS-0/
              @hand_gesture.process_event(:no_hands)
            else
              send_data "ERROR\r\nReceived Unknown data:#{data}\r\n "
          end
        end
      rescue Statemachine::TransitionMissingException => bang
        puts "ERROR\n#{bang}"
      end
    end
  end
end