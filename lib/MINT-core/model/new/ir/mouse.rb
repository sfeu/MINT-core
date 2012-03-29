
module MINT2
  class Mouse  < Pointer
    def initialize_statemachine
      if @statemachine.nil?
        parser = StatemachineParser.new(self)
        @statemachine = parser.build_from_scxml "#{File.dirname(__FILE__)}/mouse.scxml"

        @statemachine.reset

      end
    end

  end
end