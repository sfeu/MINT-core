module MINT


  class CarouFredSelImage < Image
    def getSCXML
      "#{File.dirname(__FILE__)}/CarouFredSelImage.scxml"
    end

    def send_displayed
      parent =  AIO.get("aui",self.name).parent
      cio =  CIO.get("cui-gfx",parent.name)
      cio.process_event :child_displayed
    end

  end

  class CarouFredSel < CIC

    property :items,            Integer,  :default => 1
    property :circular,         Boolean,  :default => false
    property :infinite,         Boolean,  :default => false
    property :auto,             Boolean,  :default => false
    property :scroll_items,     String,   :default => "page"
    property :scroll_fx,        String,   :default => "none"
    property :scroll_duration,  Integer,  :default => 200

    def getSCXML
      "#{File.dirname(__FILE__)}/CarouFredSel.scxml"
    end

    #functions called from scxml

    def display_children
      children = MINT::AISinglePresence.get("aui",self.name).children
      @number_of_children =children.length

    end

    def is_last_child?
      p "islast:#{@number_of_children}"
      @number_of_children == 0
    end

    def receive_displayed
      @number_of_children -= 1
      p "after reduction #{@number_of_children}"
    end

  end

end