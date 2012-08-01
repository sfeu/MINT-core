module MINT

  class RadioButton < CIO
    def getSCXML
         "#{File.dirname(__FILE__)}/radiobutton.scxml"
       end
  end
end