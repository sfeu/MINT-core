module MINT
  class Wheel < Interactor

    def initialize_statemachine
      if @statemachine.blank?
        @statemachine = Statemachine.build do

          trans :disconnected,:connect, :connected
          trans :connected, :disconnect, :disconnected

          superstate :connected do
            trans :stopped,:regress, :regressing
            trans :stopped,:progress, :progressing

            trans :regressing, :regress, :regressing
            trans :regressing, :stop, :stopped
            trans :regressing, :progress, :progressing

            trans :progressing, :progress, :progressing
            trans :progressing, :stop, :stopped
            trans :progressing, :regress, :regressing

            state :regressing do
              on_entry :start_timeout
              on_exit :stop_timeout
            end
            state :progressing do
              on_entry :start_timeout
              on_exit :stop_timeout
            end
          end
        end
      end
    end
     def start_timeout
        if not @timer
          @timer = EventMachine::Timer.new(0.3) do
            process_event("stop")
          end
        else
          puts "timer already started!!!"
        end
      end
      def stop_timeout
        if @timer
          @timer.cancel
          @timer = nil
        end
      end
  end
end
