module MINT
  class AIMultiChoiceElement < AIChoiceElement
    def initialize_statemachine
      if @statemachine.blank?
        parser = StatemachineParser.new(self)
        @statemachine = parser.build_from_scxml "#{File.dirname(__FILE__)}/aimultichoiceelement.scxml"
        @statemachine.reset
      end
    end
  end
end