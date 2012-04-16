module MINT
  class AISinglePresence < AIContainer
    property :active_child, String

    def getSCXML
      "#{File.dirname(__FILE__)}/aisinglepresence.scxml"
    end

    # hook that is called from a child if it enters presenting state
    def child_to_presenting(child)
      children.each do |e|
        e.process_event(:suspend) if e.name != child.name and not e.is_in? :suspended
      end
      attribute_set(:active_child, child.name)
    end

    def present_first_child
      children[0].process_event :present
      attribute_set(:active_child, children[0].name)
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
      if attribute_get(:active_child)
        c = MINT::AIO.get("aui",attribute_get(:active_child))
        return true if c.next
      end
  false
      end

    def exists_prev_child
      if attribute_get(:active_child)
             c = MINT::AIO.get("aui",attribute_get(:active_child))
             return true if c.previous
           end
       false
    end

  end

end
