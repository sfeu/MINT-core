module MINT
  class AIContext < AIOUT
    #Todo check this
    property :text, String
    #has 1, :context, 'AIO'

    def getSCXML
          "#{File.dirname(__FILE__)}/aicontext.scxml"
    end

  end
end
