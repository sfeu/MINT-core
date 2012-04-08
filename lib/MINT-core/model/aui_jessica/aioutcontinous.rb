module MINT
  class AIOUTContinous < AIOUT
    #Todo check this
    #property :min, Integer
    #property :max, Integer

    def initialize_statemachine
      if @statemachine.blank?
        #parser = StatemachineParser.new(self)
        #@statemachine = parser.build_from_scxml "#{File.dirname(__FILE__)}/aioutcontinuous.scxml"
        @statemachine = Statemachine.build do
          superstate :AIOUTContinuous do
            trans :initialized, :organize, :organized
            trans :organized, :present, :presenting
            trans :organized, :suspend, :suspended
            state :suspended do
              on_entry :sync_cio_to_hidden
              event :present, :presenting
              event :organize, :organized
            end

            parallel :presenting do
              on_entry [:sync_cio_to_displayed, "@d=consume(id)"]
              event :suspend, :suspended
              statemachine :s1 do
                superstate :p do
                  trans :waiting, :move, :progressing, nil, "@d>data"
                  trans :waiting, :move, :regressing, nil, "@d<data"
                  superstate :moving do
                    event :halt, :waiting
                    trans :progressing, nil, :regressing, nil, "@d<data"
                    trans :progressing, nil, :max, nil, "@d == max"
                    trans :regressing, nil, :progressing, nil, "@d>data"
                    trans :regressing, nil, :min, nil, "@d == min"
                    trans :min, nil, :progressing, nil, "@d>data"
                    trans :max, nil, :regressing, nil, "@d<data"
                  end
                end
              end
              statemachine :s2 do
                superstate :f do
                  state :defocused do
                    on_entry :sync_cio_to_displayed
                    event :focus, :focused
                  end
                  superstate :focused do
                    on_entry :sync_cio_to_highlighted
                    event :defocus, :defocused
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end