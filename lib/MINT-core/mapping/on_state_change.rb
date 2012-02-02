
module MINT

  # Basic mapping that observes state changes of elements in a model agents model.
  #
  class ExecuteOnStateChange < Mapping
    attr_reader :state

    def initialize(source_model,state,execute, initial=nil)
      super(source_model,"write",execute,initial)
      if (not state.is_a? Array)
        @state = [state.to_s]
      else
        @state = state.map &:to_s
      end
    end

    def execute
      # query existing state
      if @initial
        results = @source_model.all({ :abstract_states=> /(^|\|)#{Regexp.quote(@state.first)}/})
        p "Found results by read: #{results.inspect}"
        results.each do |result|
          call_if_result_matches result, @initial
        end
      end
      #register for further events
      #observer = agent.storage.notify 'write', {"_model_"=> @source_model.to_s} + @conditions

      p "registered for model #{@source_model} writes on state #{@state}"
      @source_model.notify("write", {  :new_states=> @state.first},self.method(:check_cond))

    end

    def check_cond(result)
      call_if_result_matches(result,@execute)
    end

    def call_if_result_matches(result,method)
      return if not result
      states_to_check = Array.new @state
      states_to_check.shift # we already hav checked for the first state
      states_to_check.each do |state|
        return false if not result.abstract_states =~/(^|\|)#{Regexp.quote(state)}/
      end
      method.call result
      true
    end

  end

  class ExecuteEventOnStateChange < ExecuteOnStateChange
    def initialize(source_model,state,selector,event)
      super(source_model,state,self.method(:process_event),nil)
      @selector = selector
      @event = event
    end

    def process_event(result)
      @selector.each do |element|
        element.process_event(@event)
      end
    end
  end
end