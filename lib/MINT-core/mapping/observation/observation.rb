class Observation

  def initialize(parameters)
    @observation = parameters
    @initiated_callback = nil
    @result = nil
    @mapping = {}
  end

  def mapping=(mapping)
    @mapping = mapping
  end

  def mapping
    @mapping
  end

  def mapping_callback
    @mapping[:state_callback]
  end

  def is_continuous?
    @observation[:continuous]
  end

  def id
    @observation[:id]
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

  def check_true_at_startup(cb)
    # check if observation is already true at startup
    model = MINT::Interactor.class_from_channel_name(element)
    e = model.first(:name=>name)
    if e
      if ((e.states & states).length>0) or ((e.abstract_states.split('|') & states).length>0)
        cb.call element, true, result(JSON.parse e.to_json)
      end
    end
  end

  def start(cb)
    state = true

    check_true_at_startup(cb)
    r = RedisConnector.sub
    r.subscribe("#{element}").callback {
      @initiated_callback.call(element) if @initiated_callback
    }

    r.on(:message) do |channel, message|
      if channel.eql? element
        found=JSON.parse message

        if name.nil? or name.eql? found["name"]

          if found.has_key? "new_states"
            if (found["new_states"] & states).length>0 # checks if both arrays share at least one element

            p "observation true: #{element}:#{name}"
            mapping_callback.call(@mapping[:mapping][:name], {:id => id, :state => :true}) if mapping_callback
              cb.call element, true , result(found)
            else
              if (found["states"] & states).length == 0
                p "observation false: #{element}:#{name}"
                if mapping_callback and state
                  mapping_callback.call(@mapping[:mapping][:name], {:id => id, :state => :false})
                  state = false
                end
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