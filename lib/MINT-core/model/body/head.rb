
module MINT
  class Head < Interactor
    attr_accessor :connection
    attr_accessor :head_angle

    #property :angle, Integer, :default  => -1
    #property :distance, Integer, :default  => -1

    def getSCXML
      "#{File.dirname(__FILE__)}/head_new.scxml"
    end

    def initialize(attributes = nil)
      super(attributes)

      start
    end

    def start(host ="0.0.0.0", port=4242)
      EventMachine::start_server host, port, StatefulProtocol do |conn|
        @connection = conn

        conn.head = self
        puts "connection..."
        self.process_event :connect
      end
      puts "Started head control server on #{host}:#{port}"
    end

    def consume_nose_movement
      @connection.consume_nose_movement = true
    end

    def consume_head_movement
      @connection.consume_head_movement = true
      [@head_x,@head_y, @head_scale, @hand_angle]
    end

    class StatefulProtocol < EventMachine::Connection
      include EM::Protocols::LineText2
      attr_accessor :head
      attr_accessor :consume_head_movement, :consume_nose_movement
      # attr_accessor :speed

      def initialize
        super()
        @consume_head_movement = false
            @consume_nose_movement = false
      end

      def receive_line(data)
        begin
          d = data.split('/')

          case d[0]
            when "Move", "HeadMove"
              if   @consume_head_movement
                head_x = d[1].gsub(',',".").to_f
                head_y = d[2].gsub(',',".").to_f
                head_scale =  d[3].gsub(',',".").to_f
                @head_angle = d[4].gsub(',',".").to_f
                @head.head_angle = @head_angle
                @head.process_event "head_move"

                @head.attribute_set(:head_angle,@head_angle)
                RedisConnector.redis.publish("out_channel:#{@head.create_channel_w_name}:testuser",@head_angle)
              end
            when "FaceMove"
              if   @consume_nose_movement
                x = d[1].gsub(',',".").to_f
                y = d[2].gsub(',',".").to_f
              end
            when 'Leave'
              #@head.process_event(:disconnect)
            when 'Enter'
              #@head.process_event(:connect)
            else
              p "ERROR\r\nReceived Unknown data:#{data}\r\n "
          end
        end
      rescue Statemachine::TransitionMissingException => bang
        puts "ERROR\n#{bang}"
      end
    end



  end
end
