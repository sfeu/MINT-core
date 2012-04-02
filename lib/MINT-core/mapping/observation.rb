class Observation

  def initialize(parameters)
    @observation = parameters
    @initiated_callback = nil
    @result = nil
  end

  def element
    @observation[:element]
  end

  def states
    @observation[:states].map &:to_s
  end

  def resultName
    @observation[:result]
  end

  def result(r)
    if r
      {resultName => r }
    else
      {}
    end
  end

  def name
    @observation[:name]
  end

  def initiated_callback(cb)
    @initiated_callback = cb
  end

  def start(cb)

    # check if observation is already true at startup
    model = MINT::Element.class_from_channel_name(element)
    e = model.first(:name=>name)
    if e
      if ((e.states & states).length>0) or ((e.abstract_states.split('|') & states).length>0)
        cb.call element, true, result(JSON.parse e.to_json)
      end
    end

    RedisConnector.sub.subscribe("#{element}").callback {
      @initiated_callback.call(element) if @initiated_callback
    }

    RedisConnector.sub.on(:message) do |channel, message|
      if channel.eql? element
        found=JSON.parse message

        if  name.eql? found["name"]

          if found.has_key? "new_states"
            if (found["new_states"] & states).length>0 # checks if both arrays share at least one element
              p "observation true: #{element}:#{name} in states #{states}"
              cb.call element, true , result(found)
            else
              if (found["states"] & states).length == 0
                cb.call element, false, {}
              end
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