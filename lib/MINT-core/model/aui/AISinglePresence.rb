module MINT
  class AISinglePresence < AIC
    def initialize_statemachine
      if @statemachine.blank?
        @statemachine = Statemachine.build do
          trans :initialized,:organize, :organized
          trans :organized, :present, :presenting
          trans :suspended, :present, :presenting
          state :suspended do
            on_entry [:sync_cio_to_hidden]
          end

          superstate :presenting do
            on_entry :present_first_child
            event :suspend, :suspended, :hide_children

            state :defocused do
              on_entry :sync_cio_to_displayed
              event :focus, :focused
            end
            superstate :focused do
              event :defocus, :defocused
              state :waiting do
                on_entry :sync_cio_to_highlighted
                event :enter, :entered
                event :next, :defocused, :focus_next,  Proc.new { exists_next}
                event :prev, :defocused, :focus_previous, Proc.new { exists_prev}
                event :parent, :defocused, :focus_parent
              end
              state :entered do
                event :leave, :waiting
                event :next, :entered, :present_next_child,  Proc.new { exists_next_child}
                event :prev, :entered, :present_previous_child, Proc.new { exists_prev_child}
              end

            end
          end
        end
      end
    end

    # hook that is called from a child if it enters presenting state
    def child_to_presenting(child)
      childs.all.each do |e|
        e.process_event(:suspend) if e.id != child.id and not e.is_in? :suspended
        end
    end

    def present_first_child
      childs[0].process_event :present
    end

    def present_next_child
      active = false
      childs.each do |c|
        if active
          c.process_event(:present)
          active = false
        else
          active = true if c.states!=[:suspended]
        end
      end
    end

    def present_previous_child
      active = false
      childs.reverse_each do |c|
        if active
          c.process_event(:present)
          active = false
        else
          active = true if c.states!=[:suspended]
        end
      end
    end

    def add_element
      f = AISingleChoiceElement.first(:new_states=> /#{Regexp.quote("dragging")}/)
      self.childs << f
      self.childs.save
      f.process_event(:drop)
      f.destroy
    end

    def exists_next_child
      self.childs.next!=nil
    end

    def exists_prev_child
      self.childs.previous!=nil
    end

  end

end
