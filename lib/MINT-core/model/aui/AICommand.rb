module MINT
  class AICommand < AIINDiscrete
    def getSCXML
      "#{File.dirname(__FILE__)}/aicommand.scxml"
    end
  end
end