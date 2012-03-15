module MINT
  class AIReference < AIINDiscrete
      has 1, :refers, 'AIO'

      def initialize_statemachine
        super
        parser = StatemachineParser.new(self)
        @statemachine = parser.build_from_scxml "#{File.dirname(__FILE__)}/aio.scxml" # TODO change to aireference.sxml

      end

    end

end