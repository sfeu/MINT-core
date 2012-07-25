class Action

def initialize

  # sucecss of action used by finisheh callback
  @result = false
end

  def id
    @action[:id]
  end

 def identifier

 end

 def initiated_callback(cb)

 end

 def start (observation_results)
   self
 end


  # This callback is used to inform that the action has been successfully finished
  def finished_callback (&block)
    block.call(id,@result)
  end


end