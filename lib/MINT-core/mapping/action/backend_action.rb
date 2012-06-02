class BackendAction < Action
  # BackendAction.new(:call => CUIControl.method(:find_cio_from_coordinates))
  def initialize(params)
      @action = params
  end

  def id
    @action[:id]
  end

  def parameter
    @action[:parameter]
  end

  def call_function
    @action[:call]
  end

  def identifier
    call_function.name.to_s
  end

  def start(observation_results)
    p = observation_results[parameter]
    call_function.call p
  end
end