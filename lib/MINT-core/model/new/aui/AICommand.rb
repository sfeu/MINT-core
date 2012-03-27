module MINT2
  class AICommand < AIINDiscrete
    def initialize_statemachine
      if @statemachine.nil?
        parser = StatemachineParser.new(self)
        @statemachine = parser.build_from_scxml "#{File.dirname(__FILE__)}/AICommand.scxml"

        @statemachine.reset

      end
    end
  end
end