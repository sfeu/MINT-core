
module AUIControl
  include MINT

  # called from AISingleChoice mapping
  def AUIControl.present_children(aisc)
    sc = AISingleChoice.first(:name=>aisc['name'])
    sc.children.each do |aio|
      aio.process_event :present
    end
  end

  def AUIControl.suspend_all
    aics = AIContainer.all(:parent =>nil)
    aics.each do |aic|
      p "Suspend AIC: #{aic.name}"
      aic.process_event :suspend
    end
  end

  def AUIControl.suspend_others(ais)
    ais = AISinglePresence.first(:name=>ais['name'])
    ais.children.each do |aio|
      aio.process_event :suspend if not aio.name.eql? ais.active_child.name
    end
  end

  # ensures that all prev/next relationships are setup properlyin one complete sequence
  def AUIControl.organize_sub(aio,parent_aio = nil, layer = 0)

    last_child = nil
    if (aio.kind_of? MINT::AIContainer)
      # aio.entry = aio.children[0]
      prev = aio
      aio.children.each do |child|
        if (child.instance_of? MINT::AIReference) # skip AIReferences for prev/next navigation
          child.process_event("organize")
          next
        end
        prev.next = child.name
        prev.process_event("organize") #if not prev.kind_of? MINT::AIContainer

        child.previous = prev.name

        prev = organize_sub(child,aio,layer+1)
        last_child = child
      end

      #prev.process_event("organize")
      return prev
    else
      return aio
    end
  end

  def AUIControl.organize(aio,parent_aio = nil, layer = 0)
    r= organize_sub(aio,parent_aio, layer )
    r.process_event("organize")
  end

  def AUIControl.organize_new (aio,prev = nil, layer = 0)
    aio.previous=prev.name  if prev

    if (aio.kind_of? MINT::AIContainer)
      prev_child = aio
      aio.children.each do |child|
        organize(child,prev_child)
        prev_child = child
      end
      if aio.children
        aio.next=aio.children[0].name
      end
    end
    aio.process_event "organize"
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
          last.next = child.name
          child.previous = last.name
        end
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

