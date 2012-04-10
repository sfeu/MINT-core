module MINT
  class AISingleChoice < AIContainer
    def initialize_statemachine
      if @statemachine.nil?
        parser = StatemachineParser.new(self)
        @statemachine = parser.build_from_scxml "#{File.dirname(__FILE__)}/aisinglechoice.scxml"
        @statemachine.reset
      end
    end

    def add(elements)
      elements.each do |e|
        self.childs << e
      end
      self.childs.save
    end

  end


  class ARContainer < AISingleChoice

  end
end