module MINT
  class Fingertip < Hand
    property :x, Integer, :default  => -1
    property :y, Integer, :default  => -1
    property :touched, Boolean, :default  => false
    property :threshold_x, Integer, :default  => 15
    property :threshold_y, Integer, :default  => 10

    property :screen_width, Integer, :default => 640
    PUBLISH_ATTRIBUTES += [:x,:y,:touched]

    # performance optimization to prevent mulitple subscribes
    @subscribed = false

    def getSCXML
      "#{File.dirname(__FILE__)}/fingertip.scxml"
    end
  end

  def cache_coordinates(x,y)
    @cached_x = x
    @cached_y = y
  end

  def start_timeout
    if not @timer
      @timer = EventMachine::Timer.new(0.3) do
        attribute_set(:x, @cached_x)
        attribute_set(:y, @cached_y)
        process_event("stop")
      end
    else
      puts "timer already started!!!"
    end
  end
  def stop_timeout
    if @timer
      # p "stopped timer"
      @timer.cancel
      @timer = nil
    end
  end

  def start_one_time_tick(time,event)
    EventMachine::Timer.new(time) {
      process_event event
    }
  end

  def restart_timeout
    stop_timeout
    start_timeout
  end

  def touch_changed?(touch)
    return  true if  attribute_get(:touched) != touch
    false
  end

  def cache_touched(touch)
    attribute_set(:touched, touch)
  end

  def filter(x,y)
    [(attribute_get(:screen_width) - x),y]
  end

  def has_moved?(x,y)
    return true if @cached_x.nil? or @cached_y.nil?
    return true if ((x-@cached_x).abs > threshold_x) or ((y-@cached_y).abs > threshold_y)
    false
  end

  def consume(id)
    # subscription = "data:"+self.class.create_channel_name+"."+id.to_s+":*"

    return if @subscribed

    redis = RedisConnector.redis

    redis.pubsub.subscribe("ss:event") { |message|

      # if (key.eql? subscription)
      data = MultiJson.decode message

      if data["e"].eql? "touches"
        touches = data["p"][0]
        touched_value,x,y = touches[0].map &:to_i

        x,y = filter x,y
        touched_value= (touched_value==0)?false:true

        if has_moved? x,y
          cache_coordinates x,y
          process_event("move") if not is_in? :moving
          restart_timeout
        else
          if is_in? :stopped
            if touch_changed? touched_value
              if touched_value
                process_event :press
              else
                process_event :release
              end
              cache_touched touched_value
            end
          end
        end
      end
      # end
    }
    @subscribed = true
  end
end