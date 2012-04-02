module MINT
  class AIContext < AIOUT
    #Todo check this
    #property :description, String
    #has 1, :context, 'AIO'

    def initialize_statemachine
      super
      #parser = StatemachineParser.new(self)
      #@statemachine = parser.build_from_scxml "#{File.dirname(__FILE__)}/aicontext.scxml"
      @statemachine = Statemachine.build do
        superstate :AIContext do
          trans :initialized, :organize, :organized
          trans :organized, :present, :presenting
          trans :organized, :suspend, :suspended
          trans :suspended, :present, :presenting
          trans :suspended, :organize, :organized

          state :suspended do
            on_entry :sync_cio_to_hidden
          end

          superstate :presenting do
            on_entry [:inform_parent_presenting]
            event :suspend, :suspended

            state :defocused do
              on_entry :sync_cio_to_displayed
            end
            state :focused do
              on_entry :sync_cio_to_highlighted
            end
            trans :defocused,:focus,:focused
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
