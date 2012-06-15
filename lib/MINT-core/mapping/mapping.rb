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
      resetObservations

      # to fire callback if all observations have been successfully initialized
      @observation_init ={}

      @activated_callback = nil
      @action_activated = {}

      # to fire callback to inform mapping state
      @state_callback = nil

      # stores variables assigned by observations
      @observation_results = {}
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


    def startAction(observation_results)
      p "Mapping #{mapping_name} executed"
      actions.each do |action|
        @action_activated[action.identifier] = false
        action.initiated_callback(self.method :activated_cb)
        p "Action activated"
        @state_callback.call(@mapping[:name], {:id => action.id, :state => :activated}) if @state_callback
        action.start observation_results   # pass observation variables
      end
    end

    def resetObservations(check=false)
      @observation_state = {}
      @mapping[:observations].each do |observation|
        @observation_state[observation.element] = false
        observation.check_true_at_startup self.method(:callback) if check and observation.is_continuous?
      end
    end

  end
end