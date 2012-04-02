module MINT
  class AIContainer < AIOUT
    #Todo check this
    has n, :childs, 'AIO',
        :parent_key => [ :id ],      # local to this model (Blog)
        :child_key  => [ :aicontainer_id ]  # in the remote model (Post)
    has 1, :entry, 'AIO'

    def initialize_statemachine
      if @statemachine.blank?
        @statemachine = Statemachine.build do
          #parser = StatemachineParser.new(self)
          #@statemachine = parser.build_from_scxml "#{File.dirname(__FILE__)}/aicontainer.scxml"
          superstate :AIContainer do
            trans :initialized,:organize, :organized
            trans :organized, :present, :p, :present_children
            trans :organized, :suspend, :suspended
            state :suspended do
              on_entry :sync_cio_to_hidden
              event :present, :p, :present_children
              event :organize, :organized
            end

            parallel :p do
              event :suspend, :suspended, :hide_children
              statemachine :s1 do
                superstate :presenting do
                  state :defocused do
                    on_entry :sync_cio_to_displayed
                  end
                  state :focused do
                    on_entry :sync_cio_to_highlighted
                  end
                  trans :defocused, :focus, :focused
                  trans :focused,:defocus, :defocused
                  trans :focused, :next, :defocused, :focus_next,  Proc.new { exists_next}
                  trans :focused, :prev, :defocused, :focus_previous, Proc.new { exists_prev}
                  trans :focused, :parent, :defocused, :focus_parent
                  trans :focused, :child, :defocused, :focus_child
                end
              end

              statemachine :s2 do
                superstate :l do
                  state :listing do
                    event :update, :listing, :sync_cio_to_updated
                  end
                end
              end
            end
          end
        end
      end
    end

    def hide_children
      if self.childs
        self.childs.each do |c|
          c.process_event(:suspend)
        end
      end
    end

    def present_children
      if self.child
        self.childs.each do |c|
          c.process_event(:present)
        end
      end
    end


    def  focus_child
      if self.childs && self.childs.first
        self.childs.first.process_event(:focus)
      else
        nil # TODO not working, find abbruchbedingung!!!
      end
    end


    # hook that is called from a child if it enters presenting state
    def child_to_presenting(child)
      true
    end
  end
end