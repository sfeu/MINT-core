module MINT

  class HandGesture < IN

    attr_accessor :command_timeout
    attr_accessor :confirm_timeout

    def initialize(attributes = {}, &block)
      super(attributes, &block)

      @issued_next = 0
      @issued_prev = 0
      @command_timeout = 60
      @confirm_timeout = 0
      @timer = nil
      @counter=0

    end

    def initialize_statemachine
      if @statemachine.nil?
        @statemachine = Statemachine.build do
          superstate :HandGesture do
            trans :NoHands, :two_hands, :TwoHands
            trans :NoHands, :one_hand, :OneHand
            trans :TwoHands, :one_hand, :OneHand
            trans :TwoHands, :no_hands, :NoHands


            superstate :OneHand do

              superstate :Command do
                trans :wait_one, :select, :selected
                trans :selected, :confirm, :confirmed
                trans :confirmed, :tick, :wait_one # tick will be triggered in on_enter(confirmed)

                state :confirmed do
                  on_entry Proc.new {@statemachine.tick }
                end

                event :widen, :w, :print_distance
                event :narrow, :n, :print_distance
                event :prev_gesture, :previous
                event :next_gesture, :next
              end

              superstate :Navigation do

                superstate :Parental do

                  superstate :n do
                    trans :narrowing, :confirm, :narrowed
                    trans :narrowing, :narrow, :narrowing,  :reset_confirm_ticker
                    trans :narrowed, :narrow, :narrowing, :print_distance
                    event :widen, :w, :print_distance

                    state :narrowing do
                      on_entry :start_confirm_timeout
                      on_exit :stop_confirm_timeout
                    end
                  end

                  superstate :w do
                    trans :widening, :confirm, :widened
                    trans :widening, :widen, :widening, :reset_confirm_ticker
                    trans :widened, :widen, :widening, :print_distance
                    event :narrow, :n, :print_distance

                    state :widening do
                      on_entry :start_confirm_timeout
                      on_exit :stop_confirm_timeout
                    end
                  end

                  event :prev_gesture, :previous
                  event :next_gesture, :next
                end

                superstate :Neighbour do

                  trans :next, :next, :next_tick, :issued_next
                  trans :next_tick, :tick, :next
                  trans :next, :prev_gesture, :previous

                  trans :previous, :previous, :previous_tick, :issued_prev
                  trans :previous_tick, :tick, :previous
                  trans :previous, :next_gesture, :next

                  state  :next do
                    on_entry :command_timeout_start_next
                    on_exit :command_timeout_stop
                  end

                  state :next_tick do
                    on_entry :tick
                  end

                  state :previous_tick do
                    on_entry :tick
                  end

                  state :previous do
                    on_entry :command_timeout_start_prev
                    on_exit :command_timeout_stop
                  end

                end

                event :select, :selected
              end

              event :two_hands, :TwoHands
              event :no_hands, :NoHands
            end
          end
        end
      end
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
      save_statemachine
      process_event :tick
      true
    end

  end

  class OneHand < HandGesture
    property :amount, Integer, :default  => -1



   

    # overwritten process event method to not save state - this will be done by activation callback
    def process_event(event, callback=nil)
      process_event!(event,callback)

    end

    def activate(state,abstract_states, atomic_states)
      @counter += 1
      puts "saved on activation #{state} #{abstract_states.join "|"} #{atomic_states}"
      #update(:states =>atomic_states.join('|'),:abstract_states=> abstract_states.join('|'),:amount=>@counter)
      attribute_set(:new_states, state)

      attribute_set(:states, atomic_states.join('|'))
      attribute_set(:abstract_states, abstract_states.join('|'))
      attribute_set(:amount, @counter)
      save
    end

    def start_ticker
      @timer = EM::PeriodicTimer.new(@command_timeout) {
        self.process_event :tick
      }
    end

    def stop_ticker
      @timer.cancel
    end

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

