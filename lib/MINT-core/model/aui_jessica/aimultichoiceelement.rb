module MINT
  class AIMultiChoiceElement < AIChoiceElement
    def initialize_statemachine
      if @statemachine.blank?
        #parser = StatemachineParser.new(self)
        #@statemachine = parser.build_from_scxml "#{File.dirname(__FILE__)}/aimultichoiceelement.scxml"
        @statemachine = Statemachine.build do
          superstate :AIMultiChoiceElement do
            trans :initialized,:organize, :organized
            trans :organized, :present, :p
            trans :organized, :suspend, :suspended
            trans :suspended, :organize, :organized
            state :suspended do
              on_entry :sync_cio_to_hidden
            end

            parallel :p do
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
                  event :suspend, :suspended
                end
              end

              statemachine :s2 do
                superstate :choice do
                  state :listed do
                    on_entry :sync_cio_to_listed
                    event :choose, :chosen
                    event :drag, :dragging
                  end
                  state :chosen do
                    on_entry :sync_cio_to_selected
                    event :unchoose, :listed
                  end
                  trans :dropped, :list, :listed
                  trans :dragging, :drop, :dropped
                end
              end
            end
          end
        end
      end
    end
  end
end