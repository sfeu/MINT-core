module MINT
  class SequentialMapping <  ComplementaryMapping

    @active_observation = nil

    def start_observations
      @active_observation = 0

      observations[@active_observation].start(@observation_results,self.method(:cb_activate_action)).is_subscribed_callback { |observation|
        @observation_state[observation.element] = false
        @state_callback.call(@mapping[:name], {:id => observation.id, :state => :activated}) if @state_callback
        call_activated_callbacks
      }
    end

    # function is called every time an observation has been fulfilled
    def cb_activate_action(element,in_state,result,id)
#      @state_callback.call(@mapping[:name], {:id => id, :state => in_state.to_s.to_sym}) if @state_callback
      @state_callback.call(@mapping[:name], {:id => id, :element => element, :result => result, :state => in_state.to_s.to_sym}) if @state_callback

      @observation_state[element] = in_state

      # ignore incoming updates of a previous observation that is still subscribed
      return if not observations[@active_observation].element.eql? element

      if in_state == :fail
            observations[@active_observation].stop # unsubscribe observation
             restart # restart mapping
             return
           end
      if in_state
        @observation_results.merge! result
        observations[@active_observation].stop # unsubscribe observation
        @active_observation += 1

        # check if already all other observations have been matched
        if observations.length <= @active_observation
          startAction(@observation_results).actions_succeeded_callback { |m,result|
                      state = :failed
                      state = :succeeded if result

                      @state_callback.call(@mapping[:name], {:id => @mapping[:id], :mapping_state => state}) if @state_callback

            # add callback for action if succeeded & implement parallel action execution
            m.restart

          }
        else # start next observation
          observations[@active_observation].start(@observation_results,self.method(:cb_activate_action))
        end
      end
    end

    def restart
      @active_observation = 0
      super
      self
    end
  end
end
