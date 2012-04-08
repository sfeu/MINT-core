module MINT

  class AIContainer < AIOUTDiscrete

    property :children, String

    def children
      p = super
      result = nil
      if p
        result=[]
        c = p.split("|")
        c.each  do |name|
          result << AIO.get("aui",name)
        end
        return result
      else
        []
      end
      []
    end

    def initialize_statemachine
      if @statemachine.nil?
        parser = StatemachineParser.new(self)
        @statemachine = parser.build_from_scxml "#{File.dirname(__FILE__)}/aicontainer.scxml"
        @statemachine.reset
      end
    end

    def hide_children
      if (self.children)
        self.children.each do |c|
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
