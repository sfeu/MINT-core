module MINT
  class AICommand < Aiindiscrete
    def initialize_statemachine
      if @statemachine.blank?
        #parser = StatemachineParser.new(self)
        #@statemachine = parser.build_from_scxml "#{File.dirname(__FILE__)}/aicommand.scxml"
        @statemachine = Statemachine.build do
          superstate :AICommand do
            trans :initialized,:organize, :organized
            trans :organized, :present, :presenting
            trans :organized, :suspend, :suspended
            state :suspended do
              on_entry :sync_cio_to_hidden
              event :present, :presenting
              event :organize, :organized
            end

            superstate :presenting do
              event :suspend, :suspended
              on_entry :inform_parent_presenting
              state :defocused do
                on_entry :sync_cio_to_displayed
              end
              superstate :focused_H do
                on_entry :sync_cio_to_highlighted
                trans :deactivated, :activate, :activated
                trans :activated, :deactivate, :deactivated
              end
              trans :defocused, :focus, :focused
              trans :focused,:defocus, :defocused
              trans :focused, :next, :defocused, :focus_next,  Proc.new { exists_next}
              trans :focused, :prev, :defocused, :focus_previous, Proc.new { exists_prev}
              trans :focused, :parent, :defocused, :focus_parent
            end
          end
        end
      end
    end
  end
end