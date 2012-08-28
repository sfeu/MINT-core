module MINT
  class AIReference < AIINDiscrete
    property :refers, String
    property :text, String

    def getSCXML
      "#{File.dirname(__FILE__)}/aireference.scxml"
    end


    def refers
      r = super
      AIO.get("aui",r)
    end
  end
end