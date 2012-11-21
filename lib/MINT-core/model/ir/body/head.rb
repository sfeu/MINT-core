
module MINT
  class Head < Body
    attr_accessor :connection
    property :head_angle, Float, :default  => Math::PI/2
    property :head_angle_threshold, Float, :default  => 0.2
    property :nose_x, Float, :default  => 0
    property :nose_x_threshold, Float, :default  => 0.05
    property :nose_y, Float, :default  => 0
    property :nose_y_threshold, Float, :default  => 0.05

    def getSCXML
      "#{File.dirname(__FILE__)}/head.scxml"
    end

    def initialize(attributes = nil)
      super(attributes)
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

    def consume_nose_movement(consume = true)
      @connection.consume_nose_movement = consume
    end

    def consume_head_movement(consume = true)
      @connection.consume_head_movement = consume
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

                if (@head.head_angle-@head_angle).abs > @head.head_angle_threshold
                  @head.process_event "head_move"
                  @head.attribute_set(:head_angle,@head_angle)
                  @channel_name =  @head.create_attribute_channel_name("head_angle")
                  RedisConnector.redis.publish @channel_name,MultiJson.encode({:name=>@head.name,:head_angle => @head_angle})
                end
              end
            when "FaceMove"
              if   @consume_nose_movement
                @nose_x = d[1].gsub(',',".").to_f
                @nose_y = d[2].gsub(',',".").to_f

                if (@head.nose_x-@nose_x).abs > @head.nose_x_threshold or (@head.nose_y-@nose_y).abs > @head.nose_y_threshold
                  @head.process_event "face_move"
                  @head.attribute_set(:nose_x,@nose_x)
                  @head.attribute_set(:nose_y,@nose_y)
                  @channel_name =  @head.create_attribute_channel_name("nose")
                  RedisConnector.redis.publish @channel_name,MultiJson.encode({:name=>@head.name,:x => @nose_x,:y =>@nose_y})
                  RedisConnector.redis.publish("out_channel:#{@head.create_channel_w_name}:testuser",MultiJson.encode({:name=>@head.name,:x => @nose_x,:y =>@nose_y}))
                end
              end
            when 'Leave'
              @head.process_event :face_lost
            when 'Enter'
              @head.process_event :face_found
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
