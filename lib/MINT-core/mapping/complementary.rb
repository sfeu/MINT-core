module MINT


  class ComplementaryCallMethod < ExecuteOnStateChange
    def initialize(source_model,state,conditions,execute)
      super(source_model,state,self.method(:executeWithConditions),nil)
      @original_execute = execute
      @conditions = conditions
      p "initialized #{conditions.inspect}"
    end

    # TODO basic condition checker still without consideration of time span :-(
    def checkConditions
      p "in check AND cond #{@conditions.inspect}"
      result = nil
      @conditions.each do |model,state|
        result=model.first( :abstract_states=> /#{Regexp.quote(state)}/)
        if result.nil?
          puts "Received #{@state} notify for model #{@source_model} but condition state #{state} of model #{model} not true"
          return false
        end
      end
      return result
    end

    def  executeWithConditions(result)
      p "Catched "
      result = checkConditions
      if result
        p "executing #{@original_execute} on #{result.inspect}"
        @original_execute.call result
      end
    end

  end

  class ComplementarySendEvent< ComplementaryCallMethod
    def initialize(source_model,state,conditions,execute)
      super(source_model,state,conditions,execute)
    end

    def  executeWithConditions(result)
      p "Catched "
      result = checkConditions
      if result
        p "executing #{@original_execute} on #{result.inspect}"
        p result.process_event(@original_execute)
      end
    end
  end

  class ComplementarySendEvents< ComplementaryCallMethod
    def initialize(source_model,state,conditions,execute)
      super(source_model,state,conditions,execute)
    end

    def  executeWithConditions(result)
      publish_events(@original_execute)
    end

  end

  class ComplementaryOR<ComplementarySendEvent
    def initialize(source_model,state,conditions,execute)
      super(source_model,state,conditions,execute)
    end

    def checkConditions
      p "in check OR cond #{@conditions.inspect}"
      result = nil
      @conditions.each do |model,state|
        state.each do |s|
          result=model.first( :abstract_states=> /#{Regexp.quote(s)}/)
          if not result.nil?
            return result
          end
        end

      end
      return false
    end
  end

  class ComplementaryMethodCall < ComplementarySendEvent
    def initialize(source_model,state,conditions,execute,callback)
      super(source_model,state,conditions,execute)
      @callback= callback
    end
    def  executeWithConditions(result)
      p "Catched "
      result = checkConditions
      if result
        p "executing #{@orginal_execute} on #{result.inspect}"
        r = result.process_event(@orginal_execute)
        @callback.call r
      end
    end

  end
end