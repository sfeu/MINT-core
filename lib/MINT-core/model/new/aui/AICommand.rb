module MINT2
  class AICommand_sync_callback < AIO_sync_callback

    def sync_cio_to_pressed
      true
    end
    def sync_cio_to_released
      true
    end
  end

  class AICommand < AIINDiscrete
    def initialize_statemachine
      if @statemachine.nil?
        parser = StatemachineParser.new(self)
        @statemachine = parser.build_from_scxml "#{File.dirname(__FILE__)}/AICommand.scxml"

        @statemachine.reset

      end
    end
    def sync_event(event)
      process_event(event, AICommand_sync_callback.new)
    end

    def sync_cio_to_pressed
      cio =  MINT2::Button.first(:name=>self.name)
      if (cio and not cio.is_in? :pressed)
        cio.sync_event(:press)
      end
      true
    end
    def sync_cio_to_released
      cio =  MINT2::Button.first(:name=>self.name)
      if (cio and not cio.is_in? :released)
        cio.sync_event(:release)
      end
      true
    end

  end

end