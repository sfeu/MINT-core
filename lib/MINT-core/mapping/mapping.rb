module MINT

  # Basic abstract class to define a mapping, which specifies a communication between model agents.
  # Therefore ia mapping listens to a source model of another agents' model for actions like e.g. new elements,
  # updates to elements or element removals.
  #
  class Mapping

    # informs mapping tool about state changes
    attr_accessor :state_callback

    def initialize(params)
      @mapping = params


      # to fire callback if all observations have been successfully initialized
      @observation_init = 0

      @activated_callback = nil
      @action_activated = {}

      # to fire callback to inform mapping state
      @state_callback = nil

      # stores variables assigned by observations
      @observation_results = {}

      @observation_state = {}

      @action_states = {}

      #overall action sucecces used for direct callback
      @actions_success = false
    end

    def mapping_name
      return @mapping[:name] if @mapping[:name]
      "unnamed"
    end

    def id
      @mapping[:id]
    end

    def observations
      @mapping[:observations]
    end

    def actions
      @mapping[:actions]
    end

    def start
      return self
    end

    def startAction(observation_results)
      @action_init = 0
      @actions_success = false
      actions.each do |action|
        @action_init += 1
        @state_callback.call(@mapping[:name], {:id => action.id, :state => :activated}) if @state_callback
        action.start(observation_results).finished_callback { |id,result|
          state = :failed
          state = :succeeded if result

          @action_states[id]=state

          @state_callback.call(@mapping[:name], {:id => action.id, :state => state}) if @state_callback
          @action_init -= 1
          if @action_init == 0
            @action_activated = true
            r = false
            r = true if not @action_states.values.include? :failed
            @actions_success = r
            call_actions_succeeded_callbacks r
          end
        }   # pass observation variables
      end
      self
    end




    # This callback is used to inform that all observations have been successfully activated (subscribed)
    def activated_callback(&block)
      return unless block

      if @mapping_activated
        block.call(self)
      else
        @activated_callbacks ||= []
        @activated_callbacks.unshift block # << block
      end
    end

    def call_activated_callbacks
      @activated_callbacks ||= []

      while cb = @activated_callbacks.pop
        cb.call(self)
      end
      @activated_callbacks.clear if @activated_callbacks
    end

    # This callback is used to inform that all actions have been finished
    def actions_succeeded_callback(&block)
      return unless block

      if @action_activated
        block.call(self,@actions_success )
      else
        @actions_succeeded_callbacks ||= []
        @actions_succeeded_callbacks.unshift block # << block
      end
    end


    def call_actions_succeeded_callbacks(result)
      @actions_succeeded_callbacks ||= []

      while cb = @actions_succeeded_callbacks.pop
        cb.call(self,result)
      end
      @actions_succeeded_callbacks.clear if @actions_succeeded_callbacks
    end

    # function is called every time an observation has been fulfilled or failed (in_state == :fail)
    def cb_activate_action(element,in_state,result,id)
      @state_callback.call(@mapping[:name], {:id => id, :element => element, :result => result, :state => in_state.to_s.to_sym}) if @state_callback

      @observation_state[element] = in_state

      if in_state == :fail
        stop_observations # unsubscribe observations
        @state_callback.call(@mapping[:name], {:id => @mapping[:id], :mapping_state => :failed}) if @state_callback
        restart # restart mapping
        return
      end
      if in_state
        @observation_results.merge! result
        # check if already all other observations have been matched
        if not @observation_state.values.include? false
          stop_observations # unsubscribe observations

          startAction(@observation_results).actions_succeeded_callback { |m,result|
            state = :failed
            state = :succeeded if result

            @state_callback.call(@mapping[:name], {:id => @mapping[:id], :mapping_state => state}) if @state_callback

            # TODO -clean restart and move check_at_startup inside observation
            # - add callback for action if succeeded & implement parallel action execution
            m.restart

          }
        end
      end
    end

    def restart
      @observation_state = {}
      @action_states = {}

      observations.each do |observation|
        @observation_state[observation.element] = false
        observation.start
      end

    end

    def stop_observations
      observations.each do |observation|
        observation.stop
      end

    end

  end


end