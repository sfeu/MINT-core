module MINT

  # click_select_mapping = Sequential.new(HWButton,:pressed,HWButton,:released, 300, { AIChoiceElement  =>"focused"},:choose)

  class Sequential < Mapping
    def initialize(source_model_1,state_1,source_model_2,state_2, state_2_conditions, min_time, max_time, conditions, error_recovery = nil)
      super(source_model_1,"write",nil,nil)
      @source_model_1= source_model_1
      @state_1= state_1
      @source_model_2= source_model_2
      @state_2= state_2
      @max_time = max_time
      @min_time = min_time
      @conditions = conditions
      @time_state_1_happened = nil
      @state_2_conditions = state_2_conditions
      @error_recovery = error_recovery
    end

    def execute
      t1 = @source_model_1.notify("write", {  :new_states=> /(^|\|)#{Regexp.quote(@state_1)}/},self.method(:save_state_1_happened))
      #    t2 = @source_model_2.notify("write", {  :abstract_states=> /#{Regexp.quote(@state_2)}/},self.method(:check_sequence))
      #   p "registered for model #{@source_model_2} writes on state #{@state_2}"
      return t1
      #,t2
    end

    def check_sequence(result)
      ms = ((Time.now-@time_state_1_happened)*1000).to_i
      if @time_state_1_happened and ((@min_time<=ms and ms <=@max_time) or (@min_time == 0 and @max_time==0))
        if (check_state_2_conditions)
          p "Sequence #{@source_model_1}=#{@state_1} --> #{@source_model_2}= #{@state_2} PROCEEDED in #{ms} ms"

          publish_events @conditions

        else
          p "Sequence #{@source_model_1}=#{@state_1} --> #{@source_model_2}= #{@state_2} FAILED #{ms}ms because of state 2 conditions "

          publish_events @error_recovery if @error_recovery

        end
      else
        p "Sequence #{@source_model_1}=#{@state_1} --> #{@source_model_2}= #{@state_2} FAILED #{ms}ms instead of min/max #{@min_time}/#{@max_time}ms"

        publish_events @error_recovery if @error_recovery

      end
      @time_state_1_happened = nil
    end

    def check_state_2_conditions
      return true if not @state_2_conditions
      @state_2_conditions.each do |model,state|
#        state.each do |s|
        result=model.first( :abstract_states=> /(^|\|)#{Regexp.quote(state)}/)
        if result.nil?
          return false
        end
        #       end
      end
      true
    end

    def save_state_1_happened(result)
      p "Sequence #{@source_model_1}=#{@state_1} OK! --> #{@source_model_2}= #{@state_2} "

      @time_state_1_happened = Time.now
#      p "State #{@state_1} of #{@source_model_1} occurred!"
      if @max_time >0
        @source_model_2.wait("write", {  :new_states=> /(^|\|)#{Regexp.quote(@state_2)}/},self.method(:check_sequence))
        p "registered for model #{@source_model_2} writes on state #{@state_2}"
      else
        result = @source_model_2.first(:abstract_states=> /(^|\|)#{Regexp.quote(@state_2)}/)
        if (result)
          p "check seq"
          check_sequence(result)
        else
          p "Sequence #{@source_model_1}=#{@state_1} --> #{@source_model_2}= #{@state_2} without time slot FAILED because of state 2 conditions"

        end
      end
    end


  end
end