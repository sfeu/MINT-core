class EventAction < Action
  # BackendAction.new(:call => CUIControl.method(:find_cio_from_coordinates))
  def initialize(params)
      @action = params
  end

  def id
    @action[:id]
  end

  def event
    @action[:event]
  end

  def target
    @action[:target]
  end

  def selector
    @action[:selector]
  end

  def start(observation_results)
    interactor_data= observation_results[target]


    interactor = MINT::Interactor.get(interactor_data["mint_model"],interactor_data["name"])

    interactor = interactor.method(selector).call if not selector.nil?
    interactor.process_event event
    self
  end

end