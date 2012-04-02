module MINT
  class AISingleChoice < AIContainer
    def initialize_statemachine
      if @statemachine.blank?
        #parser = StatemachineParser.new(self)
        #@statemachine = parser.build_from_scxml "#{File.dirname(__FILE__)}/aisinglechoice.scxml"
        @statemachine = Statemachine.build do
          superstate :AISingleChoice do
            trans :initialized,:organize, :organized
            trans :organized, :present, :p, :present_children
            trans :organized, :suspend, :suspended
            trans :suspended, :organize, :organized
            state :suspended do
              on_entry :sync_cio_to_hidden
              event :present, :p, :present_children
            end
            parallel :p do
              event :suspend, :suspended, :hide_children
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
                  trans :focused, :child, :defocused, :focus_child
                end
              end

              statemachine :s2 do
                superstate :dropping do
                  trans :listing, :drop, :dropped, ["@aios = MINT::AISingleChoiceElement.all(:new_states=> /#{Regexp.quote("dragging")}/)", "add(@aios)", "@aios.each do |aio| aio.process_event :drop end"], "self.is_in?(:focused)"
                  trans :dropped, nil, :listing, ["self.process_event(:defocus)", "@aios.each do |aio| aio.process_event :focus end"]
                end
              end
            end
          end
        end
      end
    end

    def add(elements)
      elements.each do |e|
        self.childs << e
      end
      self.childs.save
    end

  end
end