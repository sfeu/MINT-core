module MINT

  class HandGesture < IN

    property :command_timeout, Integer, :default => 60
    property :confirm_timeout, Integer, :default => 0

    before :create, :initialize_counters

    def initialize_counters
      @issued_next = 0
      @issued_prev = 0
      @timer = nil
      @counter=0
    end

    def command_timeout_start_next
#    puts "entering timeout ticker next"

      @timer = EM::PeriodicTimer.new(@command_timeout) {
        process_event :next
        puts "next:#{@issued_next}"

      }
    end

    def command_timeout_start_prev
      #   puts "entering timeout ticker prev"

      @timer = EM::PeriodicTimer.new(@command_timeout) {
        process_event :previous
        puts "previous:#{@issued_prev}"
      }
    end

    def command_timeout_stop
#    puts "leaving timeout ticker"

      @timer.cancel if @timer # if gestureserver is restarted and was set to next before timer could be nil
      @issued_next = 0
      @issued_prev = 0
    end

    def start_confirm_timeout
      #   puts "entering confirm timeout ticker"
      @timer = EM::Timer.new(@confirm_timeout) {
        process_event :confirm
      #   puts "zoom confirmed"
      }
    end

    def stop_confirm_timeout
      #puts "stoped confirm timeout ticker"
      @timer.cancel
    end

    def print_distance(d)
      puts "Distance:#{d}"
    end

    def reset_confirm_ticker(d)
      print_distance d
      #puts "reseted confirm ticker"
      stop_confirm_timeout
      start_confirm_timeout
    end

    def issued_next
      @issued_next+=1
      puts "next #{@issued_next}"
      true
    end

    def issued_prev
      @issued_prev+=1
      puts "prev #{@issued_prev}"
      true
    end

    def tick
      process_event :tick
      true
    end

  end

  class OneHand < HandGesture



    def restart_ticker
      stop_ticker
      start_ticker
    end

    def start_timeout
      p "Timeout started 60 s"
      @timeout = EM::Timer.new(60) {
        p "timeout60s fired"
        process_event :to_clock
      }
    end

    def stop_timeout
      @timeout.cancel if @timeout
    end

    def restart_timeout
      stop_timeout
      start_timeout
    end
  end

  class TwoHands < HandGesture
  end

  class NoHands < HandGesture
  end

  class Speed < Interactor
    property :value, Integer, :default  => -1

    def initialize_statemachine
      if @statemachine.nil?
        @statemachine = Statemachine.build do
          trans :set,:faster,:fast
          trans :set,:slower, :slow
          trans :fast,:tick,:set
          trans :slow,:tick,:set

          state :slow do
            on_entry Proc.new {process_event :tick }
          end
          state :fast do
            on_entry Proc.new {process_event :tick }
          end
        end
      end
    end
  end

end

