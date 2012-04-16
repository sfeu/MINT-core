module MINT
  class AICommand_sync_callback < MINT::AIO_sync_callback

    def sync_cio_to_pressed
      true
    end
    def sync_cio_to_released
      true
    end
  end

  class AICommand < AIINDiscrete

    def getSCXML
          "#{File.dirname(__FILE__)}/aicommand.scxml"
    end

    def sync_event(event)
      process_event(event, AICommand_sync_callback.new)
    end

    def sync_cio_to_pressed
      cio =  Button.first(:name=>self.name)
      if (cio and not cio.is_in? :pressed)
        cio.sync_event(:press)
      end
      true
    end
    def sync_cio_to_released
      cio =  Button.first(:name=>self.name)
      if (cio and not cio.is_in? :released)
        cio.sync_event(:release)
      end
      true
    end

  end

end