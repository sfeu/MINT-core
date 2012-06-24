class Observation

  def initialize(parameters)
    @observation = parameters
    @cb_observation_has_subscribed = false

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
    if resultName and r
      {resultName => r }
    else
      {}
    end
  end

  def name
    if @observation[:name] =~ /\./ # check if refers to variable used in sync mappings
      variable,attribute = @observation[:name].split "."
      if (@observation_results and @observation_results.has_key? variable)
        interactor_data= @observation_results[variable]
        interactor = MINT::Interactor.get(interactor_data["mint_model"],interactor_data["name"])

        r = interactor.method(attribute).call
        return r
      end
    else
      return @observation[:name]
    end
  end

  def check_true_at_startup(cb)
    # check if observation is already true at startup
    model = MINT::Interactor.class_from_channel_name(element)
    e = model.first(:name=>name)

    if e
      e_states= e.states.map &:to_s
      if ((e_states & states).length>0) or ((e.abstract_states.split('|') & states).length>0)
        cb.call element, true, result(JSON.parse e.to_json),id
        return true
      end
    end
    return false
  end

  def stop
    RedisConnector.sub.unsubscribe("#{element}")
    @cb_observation_has_subscribed = false

  end

  def start(observations_results,cb)
    @observation_results=observations_results
    res = check_true_at_startup(cb) if is_continuous?

    if not res
    r = RedisConnector.sub
    r.subscribe("#{element}").callback {
      @cb_observation_has_subscribed = true
      call_subscribed_callbacks
    }

    r.on(:message) do |channel, message|
      if channel.eql? element
        found=JSON.parse message

        if name.nil? or name.eql? found["name"]

          if found.has_key? "new_states"
            if (found["new_states"] & states).length>0 # checks if both arrays share at least one element

              p "observation true: #{element}:#{name}"
              # Observation state == true
              cb.call element, true , result(found),id
            else
              if (found["states"] & states).length == 0
                # Observation state == false
                p "observation false: #{element}:#{name}"
                cb.call element, false, {},id
              end
            end
          end
        end
      end
    end
    end
    self
  end



   # This callback is used to inform that the observation has been successfully subscribed
  def is_subscribed_callback(&block)
    return unless block

    if @cb_observation_has_subscribed
      block.call(self)
    else
      @subscribed_callbacks ||= []
      @subscribed_callbacks.unshift block # << block
    end
  end

  def call_subscribed_callbacks
    @subscribed_callbacks ||= []
    while cb = @subscribed_callbacks.pop
      cb.call(self)
    end
    @subscribed_callbacks.clear if @subscribed_callbacks
  end

end