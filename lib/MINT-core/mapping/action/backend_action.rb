class BackendAction < Action
  # BackendAction.new(:call => CUIControl.method(:find_cio_from_coordinates))
  def initialize(params)
      super()
      @action = params
  end


  def parameter
    return [] if @action[:parameter].nil?
    @action[:parameter].split(',')
  end

  def call_function
    @action[:call]
  end

  def identifier
    call_function.name.to_s
  end

  def start(observation_results)
    @result = false
    params = []
    parameter.each { |p|
      params << observation_results[p]
    }

    @result = call_function.call *params
    self
  end
end