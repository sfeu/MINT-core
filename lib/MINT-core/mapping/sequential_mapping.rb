module MINT
  class SequentialMapping <  ComplementaryMapping

    @active_observation = nil

    def start_observations
      @active_observation = 0

      p "Observation #{observations[@active_observation].name} activated"

      observations[@active_observation].start(self.method(:cb_activate_action)).is_subscribed_callback { |observation|
        @observation_state[observation.element] = false
        @state_callback.call(@mapping[:name], {:id => observation.id, :state => :activated}) if @state_callback
        call_activated_callbacks
      }
    end

    # function is called every time an observation has been fulfilled
    def cb_activate_action(element,in_state,result,id)
      @state_callback.call(@mapping[:name], {:id => id, :state => in_state.to_s.to_sym}) if @state_callback

      if in_state
        @observation_results.merge! result
        observations[@active_observation].stop # unsubscribe observation
        @active_observation += 1

        # check if already all other observations have been matched
        if observations.length <= @active_observation
          startAction(@observation_results).actions_succeeded_callback { |m|
            @state_callback.call(@mapping[:name], {:id => @mapping[:id], :mapping_state => :finished}) if @state_callback

            # add callback for action if succeeded & implement parallel action execution
            m.restart

          }
        else # start next observation
          observations[@active_observation].start(self.method(:cb_activate_action))
        end
      end
    end
  end
end
