module MINT
  class AIReference < AIINDiscrete
    property :refers, String

    def initialize_statemachine
      if @statemachine.nil?
        parser = StatemachineParser.new(self)
        @statemachine = parser.build_from_scxml "#{File.dirname(__FILE__)}/aireference.scxml"
        @statemachine.reset
      end
    end

    def refers
      r = super
      AIO.get("aui",r)
    end
  end
end