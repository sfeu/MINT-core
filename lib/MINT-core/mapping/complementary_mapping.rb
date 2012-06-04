class ComplementaryMapping

  attr_accessor :state_callback

  def initialize(params)
    @mapping = params
    resetObservations

    # to fire callback if all observations have been successfully initialized
    @observation_init ={}
    @initialized_callback = nil

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

  def start
    p "Mapping #{@mapping[:name]} started"
    @state_callback.call(@mapping[:name], {:id => @mapping[:id], :mapping_state => :started}) if @state_callback
    observations.each do |observation|
      @observation_init[observation.element] = false
      observation.initiated_callback(self.method :init_cb)
      p "Observation #{observation.name} activated"
      @state_callback.call(@mapping[:name], {:id => observation.id, :state => :activated}) if @state_callback
      observation.start self.method(:callback)
    end
    @activated_callback.call  if @activated_callback
  end

  def observations
    @mapping[:observations]
  end

  def actions
    @mapping[:actions]
  end

  def init_cb(element)
    if @initialized_callback
      @observation_init[element] = true
      if not @observation_init.values.include? false
        @initialized_callback.call
      end
    end
  end

  def activated_cb(element)
    if @activated_callback
      @action_activated[element] = true
      if not @action_activated.values.include? false
        @activated_callback.call
      end
    end
  end

  def callback(element,in_state,result)

    @observation_state[element] = in_state
    if in_state

      @observation_results.merge! result

      # check if already all other observations have been matched
      if not @observation_state.values.include? false
        startAction @observation_results
        resetObservations true
      end
    end
  end

  def startAction(observation_results)
    p "Mapping #{mapping_name} executed"
    actions.each do |action|
      @action_activated[action.identifier] = false
      action.initiated_callback(self.method :activated_cb)
      p "Action activated"
      #@state_callback.call(@mapping[:name], {:id => action.id, :state => :activated}) if @state_callback
      action.start observation_results   # pass observation variables
    end
  end

  def resetObservations(check=false)
    @observation_state = {}
    @mapping[:observations].each do |m|
      @observation_state[m.element] = false
      m.check_true_at_startup self.method(:callback) if check and m.is_continuous?
    end
  end

  def activated_callback(cb)
    @activated_callback = cb
  end

  def initialized_callback(cb)
    @initialized_callback = cb
  end

end
