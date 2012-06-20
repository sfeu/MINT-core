module MINT
  class ComplementaryMapping <  Mapping
    def start
      p "Mapping #{@mapping[:name]} started"
      @state_callback.call(@mapping[:name], {:id => @mapping[:id], :mapping_state => :started}) if @state_callback
      start_observations
    end

    def restart
      p "Mapping #{@mapping[:name]} restarted"
      @state_callback.call(@mapping[:name], {:id => @mapping[:id], :mapping_state => :restarted}) if @state_callback
      start_observations
    end

    def start_observations
      @observation_init = 0
      observations.each do |observation|
        @observation_init += 1
        p "Observation #{observation.name} activated"
        observation.start(self.method(:cb_activate_action)).is_subscribed_callback { |observation|
          @observation_state[observation.element] = false
          @state_callback.call(@mapping[:name], {:id => observation.id, :state => :activated}) if @state_callback
          @observation_init -= 1
          if @observation_init == 0
            @mapping_activated = true
            call_activated_callbacks
          end
        }
      end
    end
  end
end
