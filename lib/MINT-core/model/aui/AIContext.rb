module MINT
  class AIContext < AIOUT
    #Todo check this
    property :text, String
    #has 1, :context, 'AIO'

    def initialize_statemachine
      if @statemachine.nil?
        parser = StatemachineParser.new(self)
        @statemachine = parser.build_from_scxml "#{File.dirname(__FILE__)}/aicontext.scxml"

        @statemachine.reset

      end
    end

  end
end
