class EventAction < Action
  # BackendAction.new(:call => CUIControl.method(:find_cio_from_coordinates))
  def initialize(params)
      @action = params
  end

  def event
    @action[:event]
  end

  def target
    @action[:target]
  end

  def start(observation_results)
    interactor_data= observation_results[target]

    interactor = MINT::Element.get(interactor_data["mint_model"],interactor_data["name"])
    interactor.process_event event

  end

end