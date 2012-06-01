module MINT
  DataMapper::Model.raise_on_save_failure = true

  class AIO < Interactor

    property :label, String
    property :description, Text,   :lazy => false

    # TODO Links are established without Datamapper's relations because of problems with cycles and self-references (AIContainer))
    property :parent, String
    property :previous, String
    property :next, String
    property :parent, String

    def getModel
      "aui"
    end

    def getSCXML
      "#{File.dirname(__FILE__)}/aio.scxml"
    end

    def parent
      p = super
      if p
        r = AIContainer.get("aui",p)
        return r
      else
        nil
      end
    end

    def parent= (p)
      if p.nil? or p.is_a? String
        super(p)
      else
        super(p.name)
      end
    end

    def parent2str
      parent.name      if  self.parent
    end

    def next
      p = super
      if p
        AIO.get("aui",p)
      else
        nil
      end
    end

    def next2str
      self.next.name if self.next
    end


    def previous
      p = super
      if p
        AIO.get("aui",p)
      else
        nil
      end
    end

    def previous2str
          previous.name if  self.previous
        end


    # hook to inform parent about presenting state
    def inform_parent_presenting
      self.parent.child_to_presenting(self) if (self.parent)
      true
    end

    def sync_event(event)
      process_event(event, AIO_sync_callback.new)
    end

    # callbacks

    def exists_next
      self.next!=nil
    end

    def exists_prev
      self.previous!=nil
    end

    def exists_parent
          self.parent!=nil
        end

    def sync_cio_to_displayed
      cio =  MINT::CIO.first(:name=>self.name)
      if (cio and not cio.is_in? :displayed)
        if (cio.is_in? :hidden or cio.is_in? :positioned)
          cio.sync_event(:display)
        else
          cio.sync_event(:unhighlight)
        end
        #cio.states=[:displayed]
      end
      true
    end

    def sync_cio_to_highlighted
      cio =  MINT::CIO.first(:name=>self.name)
      if (cio and not cio.is_in? :highlighted)
        cio.sync_event(:highlight)
        # cio.states=[:highlighted]
      end
      true
    end

    def sync_cio_to_hidden
      cio =  MINT::CIO.first(:name=>self.name)
      if (cio and not cio.is_in? :hidden)
        cio.sync_event(:hide)
      end
      true
    end

    def focus_previous
      if (self.previous)
        self.previous.process_event("focus")
      else
        return false # TODO not working, find abbruchbedingung!!!
      end
    end

    def focus_parent
      if (self.parent)
        self.parent.process_event("focus")
      else
        return false # TODO not working, find abbruchbedingung!!!
      end
    end

    def focus_next
      if (self.next)
        if self.next.process_event("focus")
          return true
        else
          puts "ERRROR #{self.next.name} could not execute focus event"
          return false
        end
      else
        puts "WARNING!! > no next element found!"
        return false
      end
    end

  end


  class AIO_sync_callback
    def sync_cio_to_highlighted
      true
    end

    def sync_cio_to_displayed
      true
    end

    def sync_cio_to_suspended
      true
    end
    def inform_parent_presenting
      true
    end
    def present_first_child
      true
    end

    def present_children
      true
    end

    def stop_publish(data)
      true
    end
  end
end