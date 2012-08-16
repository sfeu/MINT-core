module MINT

  class MarkableRadioButton < RadioButton
    def getSCXML
         "#{File.dirname(__FILE__)}/markableradiobutton.scxml"
       end
  end
end