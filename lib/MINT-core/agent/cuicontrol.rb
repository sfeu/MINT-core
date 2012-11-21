module CUIControl
  include MINT

  @active_cios = []
  @cached_highlighted = nil

  def CUIControl.clearHighlighted
    @cached_highlighted = nil

  end
  def CUIControl.retrieveHighlighted
    if (@cached_highlighted)
      check = MINT::CIO.get(@cached_highlighted)
      if (check.is_in? "highlighted")
        return check
      end
    end

    new_highlighted =  MINT::CIO.first(:states=>/highlighted/)

    if new_highlighted
      @cached_highlighted= new_highlighted.name
    else
      @cached_highlighted = nil
    end

    return new_highlighted
  end

  def CUIControl.find_cio_from_coordinates(result)
    # puts "mouse stopped #{result.inspect}"
    if result == nil or @active_cios.length ==0# we have not finished cui poition calculation, but we already received a mouse stopped event
      return true

    end
    x = result["x"]
    y = result["y"]

    highlighted_cio = retrieveHighlighted()

    if (highlighted_cio!=nil && highlighted_cio.x<=x && highlighted_cio.y<=y && highlighted_cio.x+highlighted_cio.width>=x && highlighted_cio.y+highlighted_cio.height>=y)
      #  puts "unchanged"
      return true
    else

      found = @active_cios.select{ |e|  e.x <=x && e.y<=y && e.x+e.width>=x && e.y+e.height>=y}

      #      puts "found #{found.inspect}"

      if (highlighted_cio)
        highlighted_cio.process_event("unhighlight")
        MINT::AIO.get(highlighted_cio.name).process_event("defocus")
        # old focus
        #      puts "unhighlight:"+highlighted_cio.name
        # @highlighted_cio.update(:state=>"calculated") # old focus
      end

      if (found.first)
        highlighted_cio = MINT::CIO.get(found.first.name)
        highlighted_cio.process_event("highlight")
        MINT::AIO.get(highlighted_cio.name).process_event("focus")
        #       puts "highlighted:"+highlighted_cio.name
      else
        #     puts "no highlight"
        return  true
      end
    end
    return true
  end

  def CUIControl.refresh_all
    aics = AIO.all(:parent =>nil).map &:name
    aics.each do |name|
      cio = CIO.get(name)
      p "refrehsing #{cio.name}"
      cio.process_event :refresh
    end
  end

  def CUIControl.fill_active_cio_cache(result=nil)
    @active_cios = CIO.all.select{ |e| e.is_in?(:displaying) and e.highlightable}
    puts "CIO cache initialized with #{@active_cios.inspect} elements"
  end

  def CUIControl.add_to_cache(cio)
    if cio['highlightable'] and not @active_cios.index{|x|x.name==cio["name"]}
      c =  CIO.get(cio["name"])
      @active_cios << c
      puts "Added #{cio['name']} to CIO cache #{c.x}/#{c.y}"

    end
    return true
  end

  def CUIControl.update_cache(cio)
    index = @active_cios.index{|x|x.name==cio["name"]}
    if index
      c =  CIO.get(cio["name"])
      @active_cios[index] = c
      puts "Updated#{cio['name']} to CIO cache #{c.x}/#{c.y} #{c.width}/#{c.height}"

    end
    return true
  end


  def CUIControl.remove_from_cache(cio)
    p "remove cache"
    if cio['highlightable']
      @active_cios.delete_if{|x| x.name == cio['name']}
      puts "Removed #{cio['name']} from CIO cache "
    end
    return true
  end

end
