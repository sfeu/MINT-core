module MINT

  class GestureButton< HWButton
    attr_reader :statemachine

    def activate(state,abstract_states, atomic_states)
      puts "activate #{state} #{abstract_states.join "|"} #{atomic_states.join "|"}"
    end

    def initialize_statemachine
      if @statemachine.blank?
        @statemachine = Statemachine.build do

          trans :disconnected,:right_appeared, :connected
          trans :connected, :right_disappeared, :disconnected

          superstate :connected do
	          trans :initialized, :select, :released
            trans :released, :confirm, :pressed
            trans :pressed, :select, :released
          end
        end
      end
    end
  end
end
