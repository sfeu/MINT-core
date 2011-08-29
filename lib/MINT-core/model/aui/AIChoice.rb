module MINT
  class AIChoice < AIC
    def initialize_statemachine
      if @statemachine.blank?
        parser = StatemachineParser.new(self)
        @statemachine = parser.build_from_scxml "lib/MINT-core/model/aui/aichoice.scxml"
=begin
 @statemachine = Statemachine.build do
          trans :initialized,:organize, :organized
          trans :organized, :present, :p_t
          trans :organized, :suspend, :suspended
          trans :suspended, :present, :p_t
          trans :suspended, :organize, :organized
          state :suspended do
            on_entry :sync_cio_to_hidden
          end

          superstate :p_t do     # TODO artificial superstate required to get following event working!
            event :suspend, :suspended
            parallel :p do
              statemachine :s1 do
                superstate :presenting do
                on_entry [:present_child, :inform_parent_presenting]
                on_exit :hide_children
                  state :defocused do
                    on_entry :sync_cio_to_displayed
                  end
                  state :focused do
                    on_entry :sync_cio_to_highlighted
                  end
                  trans :defocused,:focus,:focused
                  trans :focused,:defocus, :presented
                  trans :focused, :next, :defocused, :focus_next,  Proc.new { exists_next}
                  trans :focused, :prev, :defocused, :focus_previous, Proc.new { exists_prev}
                  trans :focused, :parent, :defocused, :focus_parent

                end
              end
              statemachine :s2 do
                superstate :l do
                  trans :listing, :drop, :listing, :add_element
                end
              end
            end
          end
        end
=end
      @statemachine.reset
      end
    end
    def add_element
      if self.is_in? :focused
        f = AISingleChoiceElement.first(:new_states=> /#{Regexp.quote("dragging")}/)
        self.childs << f
        self.childs.save
        f.process_event(:drop)
        f.process_event(:focus)
        self.process_event(:defocus)
        f.destroy
      end
    end
  end

end
