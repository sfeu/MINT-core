
# Core synchronization mappings between CIO and AIO states

# Sync CIO to displaying
o1 = Observation.new(:element =>"Interactor.AIO", :states =>[:presenting],:result=>"aio",:process => :continuous)
o2 = NegationObservation.new(:element =>"Interactor.CIO", :name =>"aio.name" ,:states =>[:displaying], :result => "cio",:process => :instant )
a = EventAction.new(:event => :display, :target => "cio")
m = MINT::SequentialMapping.new(:name=>"Sync CIO to displaying", :observations => [o1,o2],:actions =>[a])
m.start

# Sync CIO to displayed
o1 = Observation.new(:element =>"Interactor.AIO", :states =>[:defocused],:result=>"aio",:process => :continuous)
o2 = NegationObservation.new(:element =>"Interactor.CIO", :name =>"aio.name" ,:states =>[:displayed], :result => "cio",:process => :instant )
a = EventAction.new(:event => :unhighlight, :target => "cio")
m = MINT::SequentialMapping.new(:name=>"Sync CIO to displayed", :observations => [o1,o2],:actions =>[a])
m.start

# Sync CIO to highlighted
o1 = Observation.new(:element =>"Interactor.AIO", :states =>[:focused],:result=>"aio",:process => :continuous)
o2 = NegationObservation.new(:element =>"Interactor.CIO", :name =>"aio.name" ,:states =>[:highlighted], :result => "cio",:process => :instant )
a = EventAction.new(:event => :highlight, :target => "cio")
m = MINT::SequentialMapping.new(:name=>"Sync CIO to highlighted", :observations => [o1,o2],:actions =>[a])
m.start

# Sync CIO to hidden
o1 = Observation.new(:element =>"Interactor.AIO", :states =>[:suspended],:result=>"aio",:process => :continuous)
o2 = NegationObservation.new(:element =>"Interactor.CIO", :name =>"aio.name" ,:states =>[:hidden], :result => "cio",:process => :instant )
a = EventAction.new(:event => :hide, :target => "cio")
m = MINT::SequentialMapping.new(:name=>"Sync CIO to hidden", :observations => [o1,o2],:actions =>[a])
m.start


# Sync AIO to presenting
o3 = Observation.new(:element =>"Interactor.CIO", :states =>[:displaying],:result=>"cio",:process => :continuous)
o4 = NegationObservation.new(:element =>"Interactor.AIO", :name =>"cio.name" ,:states =>[:presenting], :result => "aio",:process => :instant)
a1 = EventAction.new(:event => :present, :target => "aio")
m1 = MINT::SequentialMapping.new(:name=>"Sync AIO to presenting", :observations => [o3,o4],:actions =>[a1])
m1.start

# Sync AIO to defocused
o3 = Observation.new(:element =>"Interactor.CIO", :states =>[:displayed],:result=>"cio",:process => :onchange)
o4 = NegationObservation.new(:element =>"Interactor.AIO", :name =>"cio.name" ,:states =>[:defocused], :result => "aio",:process => :instant)
a2 = EventAction.new(:event => :defocus, :target => "aio")
m2 = MINT::SequentialMapping.new(:name=>"Sync AIO to defocused", :observations => [o3,o4],:actions =>[a2])
m2.start

# Sync AIO to focused
o3 = Observation.new(:element =>"Interactor.CIO", :states =>[:highlighted],:result=>"cio",:process => :onchange)
o4 = NegationObservation.new(:element =>"Interactor.AIO", :name =>"cio.name" ,:states =>[:focused], :result => "aio",:process => :instant)
a1 = EventAction.new(:event => :focus, :target => "aio")
m1 = MINT::SequentialMapping.new(:name=>"Sync AIO to focused", :observations => [o3,o4],:actions =>[a1])
m1.start

# Sync AIO to suspended
o3 = Observation.new(:element =>"Interactor.CIO", :states =>[:hidden],:result=>"cio",:process => :continuous)
o4 = NegationObservation.new(:element =>"Interactor.AIO", :name =>"cio.name" ,:states =>[:suspended], :result => "aio",:process => :instant)
a1 = EventAction.new(:event => :suspend, :target => "aio")
m1 = MINT::SequentialMapping.new(:name=>"Sync AIO to suspended", :observations => [o3,o4],:actions =>[a1])
m1.start

