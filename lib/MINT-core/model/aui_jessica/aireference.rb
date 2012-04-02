module MINT
  class AIReference < Aiindiscrete
    has 1, :refers, 'AIO'

    def initialize_statemachine
      super
      parser = StatemachineParser.new(self)
      @statemachine = parser.build_from_scxml "#{File.dirname(__FILE__)}/aireference.scxml"

    end

  end

end