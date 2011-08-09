module MINT
  class AISingleChoiceElement < AIINChoose
    def initialize_statemachine
      if @statemachine.blank?
        @statemachine = Statemachine.build do

#          superstate :AIO do # TODO not supported so far!
          trans :initialized,:organize, :organized
          trans :organized, :present, :p
          superstate :p_t do
            parallel :p do
              statemachine :s1 do
                superstate :presenting do
                  state :defocused do
                    on_entry :sync_cio_to_displayed
                  end
                  state :focused do
                    on_entry :sync_cio_to_highlighted
                  end
                  trans :defocused,:focus,:focused
                  trans :focused, :defocus, :defocused
                  trans :focused, :next, :defocused, :focus_next,  Proc.new { exists_next}
                  trans :focused, :prev, :defocused, :focus_previous, Proc.new { exists_prev}
                  trans :focused, :parent, :defocused, :focus_parent
                  trans :suspended,:present, :defocused    # suspended is inside the presenting state, as it still can be in dragging mode during it is switched to suspended
                  state :suspended do
                    on_entry :sync_cio_to_hidden
                  end
                  event :suspend, :suspended

                end
              end
              statemachine :s2 do
                superstate :choice do
                  trans :listed, :choose, :chosen
                  trans :chosen, :unchoose, :listed

                  trans :listed,  :drag, :dragging
                  trans :dragging, :drop, :dropped #, :remove_from_origin
                  trans :dropped, :list, :listed
                  trans :dropped, :drag, :dragging

                  state :chosen do
                    on_entry [:sync_cio_to_selected,:unchoose_others]
                  end

                  state :listed do
                    on_entry :sync_cio_to_listed
                  end

                end
              end
            end
          end
        end
      end
    end
    def remove_from_origin
        self.parent.childs.get(self.id).destroy
    end
  end
end
