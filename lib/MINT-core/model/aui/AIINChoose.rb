module MINT
  class AIINChoose_sync_callback < AIO_sync_callback
     def initialize(element)
       @element=element
     end
     def sync_cio_to_listed
       true
     end

     def sync_cio_to_selected
       true
     end



     def unchoose_others
       aios = @element.parent.childs.all(:states=>/chosen/)
       aios.each do |aio|
         aio.process_event("unchoose") if aio.is_in? :chosen
       end
       true
     end
   end

   class AIINChoose < AIINDiscrete

     def sync_event(event)
       process_event(event, AIINChoose_sync_callback.new(self))
     end
     def sync_cio_to_selected
       cio =  MINT::Selectable.first(:name=>self.name)
       if (cio and not cio.is_in? :selected)
         cio.sync_event(:select)
       end
       true
     end

     def sync_cio_to_listed
       cio =  MINT::Selectable.first(:name=>self.name)
       if (cio and not cio.is_in? :listed)
         cio.sync_event(:select)
       end
       true
     end

     def unchoose_others
       aios = self.parent.childs.all(:states=>/chosen/)
       aios.each do |aio|
         aio.process_event("unchoose") if not aio.is_in? :unchosen
       end
     end
   end

end
