module MINT
  class AIMultiChoiceElement < AIINChoose
    def initialize_statemachine
      if @statemachine.blank?
        @statemachine = Statemachine.build do

#          superstate :AIO do # TODO not supported so far!
          trans :initialized,:organized, :organized
          trans :organized, :present, :p
          trans :hidden,:present, :initialized

          parallel :p do
            statemachine :s1 do
              superstate :presenting do
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
                event :suspend, :hidden
              end
            end
            statemachine :s2 do
              superstate :choice do
                trans :listed, :choose, :chosen
#                trans :chosen, :drag, :dragging
 #               trans :dragging, :drop, :chosen
              trans :chosen, :unchoose, :listed

                trans :listed,  :drag, :dragging
                trans :dragging, :drop, :listed
                
                state :chosen do
                  on_entry :sync_cio_to_selected
                end

                state :listed do
                  on_entry :sync_cio_to_listed
                end

              end
            end
          end
          #end
        end
      end
    end
    
  end
end