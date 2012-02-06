


class AUIAgent < MINT::Agent
  include AUIControl
  
  def initialize
    super
  end
  
  def initial_calculation(result)
   
    current_screen = Screen.first_or_create(:name => "current_screen")
    current_screen.process_event(:calculate)

    pts = InteractionTask.all(:abstract_states => /running/).map &:name
    p  "Initial Layout recalculation requested for new PTS #{pts.inspect} "   
   
    root = AUIControl.find_common(pts)

    #layer=0
    # remove all layoutements
    # Layoutelement.all.destroy
    mask = AIO.first(:name=>root)
    AUIControl.organize2(mask)
    
 #   mask=composeScreen(root,true,layer)
    mask.save
    
    current_screen.update(:root=>root) # BUG/??w thereafter no iteration in calculateMinimumSizes is possible???
    current_screen.process_event(:done)
    p "finished: AUI root>#{root}"
  end
  
  end
# DataMapper::Logger.new("log/datamapper.log", :debug)


