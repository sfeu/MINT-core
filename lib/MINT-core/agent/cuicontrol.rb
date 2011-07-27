module CUIControl
  include MINT
  
  @highlighted_cio = nil
  
  @active_cios = nil
  
  def CUIControl.find_cio_from_coordinates(result)
    puts "mouse stopped #{result.inspect}"
    if result == nil or @active_cios == nil  # we have not finished cui poition calculation, but we already received a mouse stopped event
      return
    end
    x = result.x
    y = result.y
   
    @highlighted_cio = CIO.first(:abstract_states=>/highlighted/)

    if (@highlighted_cio && @highlighted_cio.x<=x && @highlighted_cio.y<=y && @highlighted_cio.x+@highlighted_cio.width>=x && @highlighted_cio.y+@highlighted_cio.height>=y)
      puts "unchanged"
      return
    else
      found = @active_cios.select{ |e|  e.x <=x && e.y<=y && e.x+e.width>=x && e.y+e.height>=y}
     
      puts "found #{found.inspect}"
      
      if (@highlighted_cio)
        @highlighted_cio.process_event("unhighlight") # old focus
        puts "unhighlight:"+@highlighted_cio.name
        # @highlighted_cio.update(:state=>"calculated") # old focus
      end
      
      if (found.first)
        @highlighted_cio = found.first
        #reload because of cached hightlighted_cio
        @highlighted_cio = CIO.first(:name=>@highlighted_cio.name)
        @highlighted_cio.process_event("highlight") 
        puts "highlighted:"+@highlighted_cio.name
      else
        puts "no highlight"
        return
      end
    end
  end

  def CUIControl.fill_active_cio_cache(result=nil)
    @active_cios = CIO.all.select{ |e| e.is_in?(:presenting) and not e.kind_of? MINT::CIC }
    #    @active = @active.sort_by{ |k| [k.x,k.y] }
    @highlighted_cio = CIO.first(:states=>"highlighted")
    puts "CIO cache initialized with #{@active_cios.length} elements"    
  end 
  
end
