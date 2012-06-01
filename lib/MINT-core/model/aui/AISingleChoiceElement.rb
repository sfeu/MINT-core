module MINT
  class AISingleChoiceElement < AIChoiceElement

    def getSCXML
          "#{File.dirname(__FILE__)}/aisinglechoiceelement.scxml"
        end

    def remove_from_choice
        p = self.parent
        p.children = p.children.delete_if{|e| e.name.eql? self.name}
        self.parent = nil
        p.save
        self.save
    end

    def choose
      if self.is_in? :unchosen
        self.process_event(:choose)
      end
    end

  end
end
