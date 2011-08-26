module MINT
  class AIC < AIOUTDiscrete
    #    belongs_to :task @TODO - Mappings unklar
    has n, :childs, 'AIO',
        :parent_key => [ :id ],      # local to this model (Blog)
        :child_key  => [ :aic_id ]  # in the remote model (Post)
    has 1, :entry, 'AIO'

    def initialize_statemachine
      super
=begin
      parser = StatemachineParser.new(self)
      @statemachine = parser.build_from_scxml "lib/MINT-core/model/aui/aic.scxml"
=end
@statemachine = Statemachine.build do
        superstate :AIC do
          trans :initialized,:organize, :organized
          trans :organized, :present, :presenting
          trans :organized, :suspend, :suspended
          trans :suspended, :present, :presenting
          trans :suspended, :organize, :organized

          state :suspended do
            on_entry :sync_cio_to_hidden
          end

          superstate :presenting do
            on_entry :inform_parent_presenting
            event :suspend, :suspended, :hide_children #TODO AIC will suspend children?

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
            trans :focused, :child, :defocused, :focus_child

          end
        end
      end
    end

    def hide_children
      if (self.childs)
        self.childs.each do |c|
          c.process_event("suspend")
        end

      end
    end

    def present_children
      if (self.childs)
        self.childs.each do |c|
          c.process_event("present")
        end

      end
    end


    def  focus_child
      if (self.childs && self.childs.first)
        self.childs.first.process_event("focus")
      else
        return nil # TODO not working, find abbruchbedingung!!!
      end
    end


    # hook that is called from a child if it enters presenting state
    def child_to_presenting(child)
      true
    end

  end


end
