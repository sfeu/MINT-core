module MINT

  class AIOUTDiscrete < AIOUT
    def initialize_statemachine
      if @statemachine.blank?
        @statemachine = Statemachine.build do
          trans :initialized,:organize, :organized
          trans :organized, :present, :p
          trans :suspended,:present, :p, :present_children
          state :suspended do
            on_entry :sync_cio_to_hidden
          end

          superstate :p_t do     # TODO artificial superstate required to get following event working!
            event :suspend, :suspended, :hide_children
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
                end
              end
              statemachine :s2 do
                superstate :l do
                  trans :listing, :update, :listing, :sync_cio_to_updated
                end
              end
            end
          end
        end
      end
    end
  end
end
