module MINT
  class AISinglePresence < AIContainer

    def getSCXML
      "#{File.dirname(__FILE__)}/aisinglepresence.scxml"
    end

    # hook that is called from a child if it enters presenting state
    def child_to_presenting(child)
      children.all.each do |e|
        e.process_event(:suspend) if e.id != child.id and not e.is_in? :suspended
      end
    end

    def present_first_child
      children[0].process_event :present
    end

    def present_next_child
      active = false
      children.each do |c|
        if active
          c.process_event(:present)
          active = false
        else
          active = true if c.states!=[:suspended]
        end
      end
    end

    def present_previous_child
      active = false
      children.reverse_each do |c|
        if active
          c.process_event(:present)
          active = false
        else
          active = true if c.states!=[:suspended]
        end
      end
    end

    def add_element
      f = AISingleChoiceElement.first(:new_states=> /#{Regexp.quote("dragging")}/)
      self.children << f
      self.children.save
      f.process_event(:drop)
      f.destroy
    end

    def exists_next_child
      self.children.next!=nil
    end

    def exists_prev_child
      self.children.previous!=nil
    end

  end

end
