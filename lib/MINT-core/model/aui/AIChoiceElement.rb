module MINT
   class AIChoiceElement < AIINDiscrete

     def unchoose_others
       aios = []
       self.parent.children.each do |c|
         if c.is_in? :chosen
           aios << c
         end
       end
       aios.each do |aio|
         aio.process_event("unchoose")
       end
     end
   end

end
