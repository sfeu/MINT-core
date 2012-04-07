module MINT
  class Pointer < Interactor
    property :x, Integer, :default  => -1
    property :y, Integer, :default  => -1

    def initialize_statemachine
      if @statemachine.nil?
        @statemachine = Statemachine.build do

          trans :disconnected,:connect, :connected
          trans :connected, :disconnect, :disconnected

          superstate :connected do
            trans :stopped, :move, :moving
            trans :moving,:move, :moving
            trans :moving,:stop,:stopped

            state :moving do
              on_entry :start_timeout
              on_exit :stop_timeout
            end
          end
        end
      end
    end

     def cache_coordinates(x,y)
      @cached_x = x
      @cached_y = y
     end

    def start_timeout
      if not @timer
        @timer = EventMachine::Timer.new(0.1) do
          attribute_set(:x, @cached_x)
          attribute_set(:y, @cached_y)

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
    def restart_timeout
      stop_timeout
      start_timeout
    end
  end

  class Pointer3D < Pointer
    property :z, Integer, :default  => -1
    attr_accessor :cached_x, :cached_y,:cached_z

    def cache_coordinates(x,y,z=nil)
      @cached_x = x if (x)
      @cached_y = y if (y)
      @cached_z = z if (z)
    end



  def start_timeout
      if not @timer
        @timer = EventMachine::Timer.new(0.1) do
          attribute_set(:x, @cached_x)
          attribute_set(:y, @cached_y)
          attribute_set(:z, @cached_z)

          process_event("stop")

        end
      else
        puts "timer already started!!!"
      end
    end

  end
end