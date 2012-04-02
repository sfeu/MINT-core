module MINT
  class AISingleChoiceElement < AIChoiceElement
    def initialize_statemachine
      if @statemachine.blank?
        #parser = StatemachineParser.new(self)
       #@statemachine = parser.build_from_scxml "#{File.dirname(__FILE__)}/aisinglechoiceelement.scxml"
        @statemachine = Statemachine.build do
          superstate :AISingleChoiceElement do
            trans :initialized, :organize, :organized
            trans :organized, :present, :p
            trans :organized, :suspend, :suspended
            trans :suspended, :organize, :organized
            state :suspended do
              on_entry :sync_cio_to_hidden
            end

            parallel :p do
              statemachine :s1 do
                superstate :presenting do
                  event :suspend, :suspended
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
                superstate :choice do
                  state :listed do
                    on_entry :sync_cio_to_listed
                    event :choose, :chosen
                    event :drag, :dragging
                  end
                  state :chosen do
                    on_entry [:sync_cio_to_selected,:unchoose_others]
                    event :unchoose, :listed
                  end
                  trans :dragging, :drop, :dropped
                  trans :dropped, :list, :listed
                end
              end
            end
          end
        end
      end
    end
  end
end