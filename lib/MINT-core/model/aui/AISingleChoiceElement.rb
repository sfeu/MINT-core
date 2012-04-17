module MINT
  class AISingleChoiceElement < AIChoiceElement

    def getSCXML
          "#{File.dirname(__FILE__)}/aisinglechoiceelement.scxml"
        end

    # TODO initalize_statemachine could be removed as soon as the scxml is working
#    def initialize_statemachine
#      p "enter init"
#      if @statemachine.nil?
#        parser = StatemachineParser.new(self)
#                          p "after parsing"
##        @statemachine = parser.build_from_scxml "#{File.dirname(__FILE__)}/aisinglechoiceelement.scxml"
#        @statemachine = Statemachine.build do
#
##          superstate :AIO do # TODO not supported so far!
#          trans :initialized,:organize, :organized
#          trans :organized, :present, :p_t
#          trans :organized, :suspend, :suspended
#          trans :suspended, :present, :p_t
#          trans :suspended, :organize, :organized
#          state :suspended do
#            on_entry :sync_cio_to_hidden
#          end
#
#          superstate :p_t do
#            event :suspend, :suspended
#            parallel :p do
#              statemachine :s1 do
#                superstate :presenting do
#                  state :defocused do
#                    on_entry :sync_cio_to_displayed
#                  end
#                  state :focused do
#                    on_entry :sync_cio_to_highlighted
#                  end
#                  trans :defocused,:focus,:focused
#                  trans :focused, :defocus, :defocused
#                  trans :focused, :next, :defocused, :focus_next,  Proc.new { exists_next}
#                  trans :focused, :prev, :defocused, :focus_previous, Proc.new { exists_prev}
#                  trans :focused, :parent, :defocused, :focus_parent
#                  trans :focused, :drag, :dragging, :choose
#                  trans :dragging, :drop, :defocused
#                end
#              end
#              statemachine :s2 do
#                superstate :selection_H do
#                  state :unchosen do
#                    on_entry :sync_cio_to_listed
#                    event :choose, :chosen
#                  end
#                  state :chosen do
#                    on_entry [:sync_cio_to_selected,:unchoose_others]
#                    event :unchoose, :unchosen
#                  end
#                end
#              end
#            end
#          end
#        end
#      end
#    end
    def remove_from_origin
        self.parent.childs.get(self.id).destroy
    end

    def choose
      if self.is_in? :unchosen
        self.process_event(:choose)
      end
    end

  end
end
