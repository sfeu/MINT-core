module MINT

    class HWButton < Interactor

      def initialize_statemachine
        if @statemachine.blank?
          @statemachine = Statemachine.build do

            trans :disconnected,:connect, :connected
            trans :connected, :disconnect, :disconnected

            superstate :connected do
              trans :released, :press, :pressed
              trans :pressed, :release, :released
            end
          end
        end
      end
    end
end