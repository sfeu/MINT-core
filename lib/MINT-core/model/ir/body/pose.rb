module MINT
  class Pose < Hand
    attr_accessor :buffer

    LEFT_HAND_POSE = 0
    RIGHT_HAND_POSE = 5

    PROCESS_RESOLUTION = 0.1

    def initialize(attributes = nil)
      super(attributes)
      @buffer = ""
      start
    end

    def start_ticker(ms)
      @ticker = EM::PeriodicTimer.new(0.8) {
        p "tick"
        self.process_event :tick
      }
    end

    def stop_ticker
      @ticker.cancel if @ticker
    end


    def start(host ="0.0.0.0", port=5000)
      EventMachine::start_server host, port, StatefulProtocol do |conn|
        @connection = conn

        conn.pose = self
        puts "connection..."
        self.process_event :connect
      end
      puts "Started pose control server on #{host}:#{port}"

      EventMachine::add_periodic_timer( PROCESS_RESOLUTION ) { process_data }

    end

    def is_new_data?(data)
      return false if data == nil or data.eql? @old_data
      @old_data = data
      true
    end

    def inform_hand_appearance
      if @no_hand
        self.process_event :one_hand
        @no_hand = false
      end
    end

    def process_data
      # -;;;;;prev;599;1877;138;74
      data = @buffer.dup # real copy
      d = data.split(';')

      return if not is_new_data? d[RIGHT_HAND_POSE]

      inform_hand_appearance

      case d[RIGHT_HAND_POSE]
        when 'prev'
          self.process_event :previous_pose
        when 'next'
          self.process_event :next_pose
        when 'select'
          self.process_event :select_pose
        when 'confirm'
          self.process_event :confirm_pose
        when '-'
          self.process_event :no_hands
          @no_hand = true
      end
    end

    class StatefulProtocol < EventMachine::Connection
      include EM::Protocols::LineText2
      attr_accessor :pose

      def initialize
        super()

      end

      def receive_line(data)
        pose.buffer = data
      end

      def unbind
        pose.process_event :disconnect
      end

    end

  end
end