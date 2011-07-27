module MINT
  class AIC < AIOUTDiscrete
    #    belongs_to :task @TODO - Mappings unklar
    has n, :childs, 'AIO',
        :parent_key => [ :id ],      # local to this model (Blog)
        :child_key  => [ :aic_id ]  # in the remote model (Post)
    has 1, :entry, 'AIO'

    def initialize_statemachine
      super

      @statemachine = Statemachine.build do
        superstate :AIO do
          trans :initialized,:organized, :organized
          trans :organized, :present, :presenting
          trans :hidden,:present, :presenting, :present_children

          state :hidden do
            on_entry :sync_cio_to_hidden
          end

          superstate :presenting do
            event :suspend, :hidden, :hide_children

            state :presented do
              on_entry :sync_cio_to_displayed
            end
            state :focused do
              on_entry :sync_cio_to_highlighted
            end
            trans :presented,:focus,:focused
            trans :focused,:defocus, :presented
            trans :focused, :next, :presented, :focus_next,  Proc.new { exists_next}
            trans :focused, :prev, :presented, :focus_previous, Proc.new { exists_prev}
            trans :focused, :parent, :presented, :focus_parent
            trans :focused, :child, :presented, :focus_child

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
