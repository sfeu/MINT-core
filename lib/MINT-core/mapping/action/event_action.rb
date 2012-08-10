class EventAction < Action
  # BackendAction.new(:call => CUIControl.method(:find_cio_from_coordinates))
  def initialize(params)
    super()
    @action = params
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
    @result = false
    results  = []
    interactor_data= observation_results[target]

    interactor_data = [interactor_data] if not interactor_data.kind_of?(Array)

    interactor_data.each do |int_data|
      interactor = MINT::Interactor.get(int_data["mint_model"],int_data["name"])
      interactor = interactor.method(selector).call if not selector.nil?

      results << interactor.process_event(event)

    end

    @result = true if results != nil and results.count(nil)==0

    self
  end

end