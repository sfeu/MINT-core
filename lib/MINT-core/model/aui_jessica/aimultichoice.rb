module MINT
  class AIMultiChoice < AISingleChoice
    def initialize_statemachine
      if @statemachine.nil?
        parser = StatemachineParser.new(self)
        @statemachine = parser.build_from_scxml "#{File.dirname(__FILE__)}/aimultichoice.scxml"

        @statemachine.reset

      end
    end
  end
end