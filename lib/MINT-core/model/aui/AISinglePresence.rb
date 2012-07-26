module MINT
  class AISinglePresence < AIContainer
    property :active_child, String

    def getSCXML
      "#{File.dirname(__FILE__)}/aisinglepresence.scxml"
    end

    def active_child
      p = super

      if p == nil
        p = children.first
        attribute_set(:active_child,p.name)

        return p
      else
        r = AIO.get("aui",p)
        return r
      end

    end



    # hook that is called from a child if it enters presenting state
    def child_to_presenting(child)
    end

    def present_next_child
      a= active_child
      a.process_event :suspend
      n = a.next
      attribute_set(:active_child,n.name)
      n.process_event :present
    end

    def present_previous_child
      a= active_child
            a.process_event :suspend
            n = a.previous
            attribute_set(:active_child,n.name)
            n.process_event :present
    end

    def add_element
      f = AISingleChoiceElement.first(:new_states=> /#{Regexp.quote("dragging")}/)
      self.children << f
      self.children.save
      f.process_event(:drop)
      f.destroy
    end

    def exists_next_child
      return true if active_child and active_child.next
      false
    end

    def exists_prev_child
      return true if active_child and active_child.previous
      false
    end

  end

end
