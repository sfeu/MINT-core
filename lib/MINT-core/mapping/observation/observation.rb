class Observation

  def initialize(parameters)
    @observation = parameters

    # state of subscription, to ensure that an observation only subscribes once
    @cb_observation_has_subscribed = false

    # defines if the ongoing subscription should act or has been temporary disabled using stop
    @should_listen = false
  end

  def is_continuous?
    @observation[:process].nil? or @observation[:process] == :continuous
  end

  def is_instant?
    @observation[:process] == :instant
  end

  def is_onchange?
    @observation[:process] == :onchange
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
    #   RedisConnector.redis.pubsub.unsubscribe_proc("#{element}",@proc_observation)
    @should_listen = false
    #@cb_observation_has_subscribed = false
    @subscribed_callbacks = []
  end

  def fail(cb)
    cb.call element, :fail , nil, id
  end

  def start(observations_results,cb)
    @observation_results=observations_results

    if @cb_observation_has_subscribed # restart!!
      @should_listen = true

      if is_instant?
        fail(cb)  if not check_true_at_startup(cb)
      elsif is_continuous?
        check_true_at_startup(cb)
      end
      return self
    end

    @proc_observation = Proc.new { |key, message|
      if @should_listen
        found=JSON.parse message

        if name.nil? or name.eql? found["name"]
          if found.has_key? "new_states"
            if (found["new_states"] & states).length>0 # checks if both arrays share at least one element
              cb.call element, true , result(found),id
            else
              if (found["states"] & states).length == 0
                cb.call element, false, {},id
              end
            end
          end
        end
      end
    }
    res = false

    res = check_true_at_startup(cb) if is_continuous? or is_instant?

    if not res and is_instant? # instant checks do not require a subscribe and directly fail if false
      fail(cb)
      return self
    end

    if not    @cb_observation_has_subscribed
      @should_listen = true
      redis = RedisConnector.redis

      redis.pubsub.psubscribe("#{element}*",@proc_observation).callback { |count|
        @cb_observation_has_subscribed = true
        call_subscribed_callbacks
      }
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