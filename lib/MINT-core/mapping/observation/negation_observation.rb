class NegationObservation < Observation

  def check_true_at_startup(cb)
    # check if observation is already true at startup
    model = MINT::Interactor.class_from_channel_name(element)
    e = model.first(:name=>name)
    e_states= e.states.map &:to_s
    if e
      if ((e_states & states).length == 0) and ((e.abstract_states.split('|') & states).length == 0)
        cb.call element, true, result(JSON.parse e.to_json),id
        return true
      end
    end
    return false
  end

  def start(observations_results,cb)
    @observation_results=observations_results

    res = false

    res = check_true_at_startup(cb) if is_continuous? or is_instant?

    if not res and is_instant? # instant checks do not require a subscribe and directly fail if false
      fail(cb)
      return self
    end


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
            if (found["new_states"] & states).length==0 # checks if both arrays share no element

              cb.call element, true , result(found),id
            else
              if (found["states"] & states).length > 0
                cb.call element, false, {},id
              end
            end
          end
        end
      end

    end
    self
  end


end