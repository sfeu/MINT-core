module MINT
  module InteractorHelpers
    def start_timeout(seconds,event,cb = nil)
        if not @timer
          @timer = EventMachine::Timer.new(seconds) do
            cb.call if cb
            process_event event
          end
        else
          puts "timer already started!!!"
        end
      end
      def stop_timeout
        if @timer
          # p "stopped timer"
          @timer.cancel
          @timer = nil
        end
      end
      def restart_timeout(seconds,event,cb = nil)
        stop_timeout
        start_timeout(seconds,event,cb)
      end
  end
end