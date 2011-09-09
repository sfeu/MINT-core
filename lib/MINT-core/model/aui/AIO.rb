module MINT


  # An abstract
  class AIO < Element
    property :label, String
    property :description, Text,   :lazy => false
    has 1, :next, self,
        :parent_key => [ :id ],       # in the remote model (Blog)
        :child_key  => [ :next_id ]  # local to this model (Post)
    has 1,  :previous, self,
        :parent_key => [ :id ],       # in the remote model (Blog)
        :child_key  => [ :prev_id ]  # local to this model (Post)


    belongs_to  :parent, 'AIC', # BUG figure out how to declare AIC
                :parent_key => [ :id ],       # in the remote model (Blog)
                :child_key  => [ :aic_id ],  # local to this model (Post)
                :required   => true



    def initialize_statemachine
      if @statemachine.blank?
        parser = StatemachineParser.new(self)
        @statemachine = parser.build_from_scxml "#{File.dirname(__FILE__)}/aio.scxml"
=begin        @statemachine = Statemachine.build do

          superstate :AIO do
            trans :initialized,:organize, :organized
            trans :organized, :present, :presenting
            trans :organized, :suspend, :suspended
            trans :suspended,:present, :presenting
            trans :suspended, :organize, :organized
            state :suspended do
               on_entry :sync_cio_to_hidden
              end

            superstate :presenting do
              on_entry :inform_parent_presenting
              event :suspend, :suspended
              state :defocused do
                on_entry :sync_cio_to_displayed
              end
              state :focused do
                on_entry :sync_cio_to_highlighted
              end
              trans :defocused,:focus,:focused
              trans :focused,:defocus, :defocused
              trans :focused, :next, :defocused, :focus_next,  Proc.new { exists_next}
              trans :focused, :prev, :defocused, :focus_previous, Proc.new { exists_prev}
              trans :focused, :parent, :defocused, :focus_parent

            end
          end
        end
=end
        @statemachine.reset
        #else
        #@statemachine.reset
      end
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

    def sync_cio_to_highlighted
      cio =  MINT::CIO.first(:name=>self.name)
      if (cio and not cio.is_in? :highlighted)
        cio.sync_event(:highlight)
        # cio.states=[:highlighted]
      end
      true
    end

    def sync_cio_to_displayed
      cio =  MINT::CIO.first(:name=>self.name)
      if (cio and not cio.is_in? :displayed)
        if (cio.is_in? :suspended)
          cio.sync_event(:display)

        else
          cio.sync_event(:unhighlight)

        end
        #cio.states=[:displayed]
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
  end
end
