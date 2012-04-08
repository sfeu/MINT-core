module MINT
  class AIINContinous < AIIN
    #Todo check this
    #property :min, Integer
    #property :max, Integer

    def initialize_statemachine
      if @statemachine.blank?
        #parser = StatemachineParser.new(self)
        #@statemachine = parser.build_from_scxml "#{File.dirname(__FILE__)}/aiincontinuous.scxml"
        @statemachine = Statemachine.build do
          superstate :AIINContinuous do
            trans :initialized, :organize, :organized
            trans :organized, :present, :presenting
            trans :organized, :suspend, :suspended
            state :suspended do
              on_entry :sync_cio_to_hidden
              event :present, :presenting
              event :organize, :organized
            end

            superstate :presenting do
              on_entry :sync_cio_to_displayed
              event :suspend, :suspended
              state :defocused do
                on_entry :sync_cio_to_displayed
                event :focus, :focused
              end
              superstate :focused do
                on_entry :sync_cio_to_highlighted
                event :defocus, :defocused
                trans :waiting, :progress, :progressing
                trans :waiting, :regress, :regressing
                superstate :moving do
                  on_entry "publish(data)"
                  event :halt, :waiting
                  trans :progressing, :regress, :regressing
                  trans :progressing, nil, :max, nil, "data == max"
                  trans :regressing, :progress, :progressing
                  trans :regressing, nil, :min, nil, "data == min"
                  trans :min, :progress, :progressing
                  trans :max, :regress, :regressing
                end
              end
            end
          end
        end
      end
    end
  end
end