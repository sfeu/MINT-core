class Observation

  def initialize(parameters)
    @observation = parameters
    @initiated_callback = nil
  end

  def element
    @observation[:element]
  end

  def states
    @observation[:states].map &:to_s
  end

  def name
    @observation[:name]
  end

  def initiated_callback(cb)
    @initiated_callback = cb
  end

  def start(cb)

    RedisConnector.sub.subscribe("#{element}").callback {
      @initiated_callback.call(element) if @initiated_callback
    }

    RedisConnector.sub.on(:message) do |channel, message|
      found=JSON.parse message

      if  name.eql? found["name"]

        if found.has_key? "new_states"
          if (found["new_states"] & states).length>0 # checks if both arrays share at least one element
            cb.call element, true
          else
            if (found["states"] & states).length == 0
              cb.call element, false
            end
          end
        end
      end
    end
  end

  def stop
    RedisConnector.sub.unsubscribe(element)
  end
end