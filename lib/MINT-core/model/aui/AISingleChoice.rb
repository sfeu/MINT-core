module MINT
  class AISingleChoice < AIContainer

    def getSCXML
      "#{File.dirname(__FILE__)}/aisinglechoice.scxml"
    end


    def add(elements)
      elements.each do |e|
        self.children << e
      end
      self.children.save
    end

  end


  class ARContainer < AISingleChoice

  end
end