
module AUIControl
 include MINT
  
  # ensures that all prev/next relationships are setup properlyin one complete sequence
  def AUIControl.organize(aio,parent_aio = nil, layer = 0)
    
    if (aio.kind_of? MINT::AIContainer)
     # aio.entry = aio.children[0]
      last = aio
      aio.children.each do |child|
        #last.next = child
        #child.previous = last

        last = organize(child,aio,layer+1) 
      end
      aio.process_event("organize")
      return last
    else
      aio.process_event("organize")
      return aio
    end
  end
 
  # connects all  aios on the same level 
  def AUIControl.organize2(aio,parent_aio = nil, layer = 0)
   # if layer == 0 
    #  aio.next = aio
    #  aio.previous = aio
   # end
 
    if (aio.kind_of? MINT::AIContainer)
      first = aio.children.first
      last = nil

      aio.children.each do |child|
        if last
        last.next = child
        end
        child.previous = last
        copy = child
        organize2(copy,nil,layer+1)
        last = child
      end
      aio.process_event!("organize")
    else
      aio.process_event!("organize")
    end
    p "organized #{aio.name}"
  end
 
  # Searches for the common root aic that contains all tasks of {elements}.
  # During the search towards the root it activates all relevant containters in the 
  # {Layout}model in case {activate} is set to true. 
  #
  # @param tasks [String} an array of strings of task names
  # @param activate [Boolean] defines if all common comtainers should be activated
  # @return [String] name of common root aic
  #
  def AUIControl.find_common_aic(tasks,activate=false, parents ={ })
    
    if tasks.length==1
      return tasks[0]
    end
    
    tasks.each do |e|
      p "processing #{e}"
      aio = AIO.first(:name=>e)
      if (aio==nil)
        throw ("AIO with name #{e} not found in AUI model!")
      end
      if (activate)
        aio.process_event("present")
      end
      if aio.parent and not parents[aio.parent.name]
        parents[aio.parent.name]=aio.name
      elsif aio.parent and parents[aio.parent.name]  
        # already existing parent, thus all further saved parents of this task needs to be removed
        puts "parents  #{parents.inspect}"
        parents.each {|k,v| 
          if (v.eql? parents[aio.parent.name] or v.eql? aio.name)
            parents.delete(k)
            p "delete key #{k} value #{v}" 
          end
        }
        parents[aio.parent.name]=aio.name
        #        parents.delete(parents.invert[ parents[aio.parent.name]])
      end
    end
    
    p "next step"
    if parents.length>0
      return find_common_aic(parents.keys,activate,parents)
    else
      return tasks.first
    end
  end
  
  def AUIControl.find_common(tasks)
    
    if tasks.length==1
      return tasks[0]
    end
    
    parents ={ }
    
    tasks.each do |name|
      t = AIO.first(:name=>name)
      tname = t.name
      parents[tname] = [tname]
      
      while (t.parent)
        parents[tname].push t.parent.name
        t = t.parent
      end
    end
    
    lasttaskname = nil
    while 1==1
      taskname = nil
      parents.keys.each_with_index do |k,i|
        if (i==0)
          taskname = parents[k].pop
        else
          comp = parents[k].pop
          if not comp.eql? taskname 
            return lasttaskname
          end
        end
      end
      lasttaskname = taskname
    end
  end
end

