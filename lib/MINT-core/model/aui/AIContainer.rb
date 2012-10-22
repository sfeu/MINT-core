module MINT

  class AIContainer < AIOUT

    property :children, String

    def children
      p = super
      result = nil
      if p
        result=[]
        c = p.split("|")
        c.each  do |name|
          result << AIO.get(name)
        end
        return result
      else
        []
      end
      []
    end

    def children= children
      if children.is_a? Array
        a= children.map { |c| c.name if not c.is_a? String}

        super(a.join("|"))
      else
        super(children)
        end
    end

    def getSCXML
      "#{File.dirname(__FILE__)}/aicontainer.scxml"
    end

    def suspend_children
      cs = self.children
      if (cs)
        cs.each do |c|
          c.process_event("suspend")
        end

      end
    end

    def present_children
      if (self.children)
        self.children.each do |c|
          c.process_event("present")
        end

      end
    end


    def  focus_child
      if (self.children && self.children.first)
        self.children.first.process_event("focus")
      else
        return nil # TODO not working, find abbruchbedingung!!!
      end
    end


    # hook that is called from a child if it enters presenting state
    def child_to_presenting(child)
      true
    end

  end

end
