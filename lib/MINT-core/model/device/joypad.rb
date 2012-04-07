module MINT

   class Joypad < Interactor
    def initialize_statemachine
      if @statemachine.blank?
        @statemachine = Statemachine.build do

          trans :disconnected,:connect, :connected
          trans :connected, :disconnect, :disconnected

          superstate :connected do
            state :released
            superstate :pressed do
              state :left
              state :right
              state :down
              state :up
              event :release, :released
            end
            event :press_left, :left
            event :press_right, :right
            event :press_up, :up
            event :press_down, :down
            event :disconnect, :disconnected
          end
        end
      end
    end
  end
end