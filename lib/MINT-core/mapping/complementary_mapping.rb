class ComplementaryMapping <  MINT::Mapping

  def start
    p "Mapping #{@mapping[:name]} started"
    @state_callback.call(@mapping[:name], {:id => @mapping[:id], :mapping_state => :started}) if @state_callback
    observations.each do |observation|
      @observation_init[observation.element] = false
      observation.cb_observation_has_subscribed = self.method :init_cb
      p "Observation #{observation.name} activated"
      @state_callback.call(@mapping[:name], {:id => observation.id, :state => :activated}) if @state_callback
      observation.start self.method(:callback)
    end
    @activated_callback.call  if @activated_callback
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


  def activated_callback(cb)
    @activated_callback = cb
  end



end
