
module MINT

  class Button_sync_callback < CIO_sync_callback
    def sync_aio_to_activated
      true
    end

    def sync_aio_to_deactivated
      true
    end

  end

  class Button < CIO

    def getModel
         "cui-gfx"
    end

    def getSCXML
          "#{File.dirname(__FILE__)}/button.scxml"
    end

    def sync_event(event)
      process_event(event, Button_sync_callback.new)
    end

    def sync_aio_to_activated
      aio =  MINT::AICommand.first(:name=>self.name)
      if (aio and not aio.is_in? :activated)
        aio.sync_event(:activate)
      end
      true
    end


    def sync_aio_to_deactivated
      aio =  MINT::AICommand.first(:name=>self.name)
      if (aio and not aio.is_in? :deactivated)
        aio.sync_event(:deactivate)
      end
      true
    end
  end
end