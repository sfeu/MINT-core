module MINT
  class AICommand < AIReference
    def getSCXML
      "#{File.dirname(__FILE__)}/aicommand.scxml"
    end
  end
end