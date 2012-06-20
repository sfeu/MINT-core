class Action

 def identifier

 end

 def initiated_callback(cb)

 end

 def start (observation_results)
   self
 end


  # This callback is used to inform that the action has been successfully finished
  def finished_callback (&block)
    block.call(self)
  end


end