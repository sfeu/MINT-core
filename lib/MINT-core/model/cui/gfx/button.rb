
module MINT

  class Button < CIO

    def getModel
         "cui-gfx"
    end

    def getSCXML
          "#{File.dirname(__FILE__)}/button.scxml"
    end


  end
end