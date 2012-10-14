
class LayoutAgent < MINT::Agent

  include CUIControl

  def initialize
    @solver = Cassowary::ClSimplexSolver.new
    super
  end

  def initial_calculation(result)
    p  "Initial Layout recalculation requested for new PTS #{result.inspect} "

    #MINT::CIO.all.each { |c|
    #  c.calculateMinimumSize
    # }


    root_cio = CIO.first(:name=>result['root'])


    # p "#{root_le} root:#{root}"
    #p "minimumspace  = "+ calculateMinimumSquareSpace(root_le).to_s

    #calculateOptSquareSpace(result.root, 800*600, 10)

    root_cio.print
    # pts = result.interactionTasks.map &:name
    #root = find_common_container(pts,true)
#    c = Box.new(:name=>le.name, :x=>0,:y=>0, :width=>1200, :height=>800, :layer=>1)
    # c.save

    root_cio.calculate_container(@solver,20)

    CUIControl.fill_active_cio_cache
    true
  end


  def calculate_layout_on_task_change(result)
    p "Layout agent has recieved task removal request #{result.inspect}"

    deactivate_layout_on_task_deactivate(result.name)
    p "after task deaktivate"
    root = find_container_to_recalculate(result.name)
    c = Box.first(:name=>root)
    setup_constraints(c)
  end
  #private

  # @param [String] taskname name of container
  # @return [String] container name to recalculate

  def find_container_to_recalculate(taskname)
    le = Layout.first(:name=>taskname)

    if le.state.eql?("inactive")
      # luis = Layout.all(:parent=>le.parent).map &:task
      #   luis.each do |name|
      #    cui = CUI.first(:task=>name)
      #    if (cui != nil)
      #      cui.destroy!
      #    end
      #  end
      find_container_to_recalculate(le.layout)
    else
      #p "Container to recalculate #{le.inspect}"
      return le.name
    end
  end

  def calculateMinimumSquareSpace(le)
    if le.type=="layoutcontainer"
      #   p "Calculating space for container #{le.name}"
      space = 0

      le.layoutelements.each do |e|
        space = space + calculateMinimumSquareSpace(e)

      end
      #  p "Calculated from container #{space}"
      le.update(:minspace => space)


      return space
    else
      #     p "Calculating space for element #{le.inspect}"
      if (le.minwidth  and le.minheight)
        space =  le.minwidth*le.minheight
        le.update(:minspace => space)
        # p "calculated from element #{space}"
        return space
      else
        return 0
      end
    end
  end

  def calculateOptSquareSpace(root_container, available_space,border)
    root_le=Layoutelement.first(:name=>root_container)
    min_space_used = root_le.minspace
    quota =  Float(available_space )/Float( min_space_used)
    # p "quota: #{quota}"
    calc_opt_square_traverse(quota, root_le,border)
  end

  def calc_opt_square_traverse(quota, root_le,border)
    max_space = root_le.minspace*quota
    kantenlaenge = Math.sqrt(max_space)
    border_space = 4 * border * kantenlaenge  -   (2 * border)**2
    optspace = root_le.minspace*quota-border_space
    #   p "Optspace for #{root_le.name} = #{optspace}"
    root_le.update(:optspace => optspace)

    if root_le.type=="layoutcontainer"
      root_le.layoutelements.each do |e|
        calc_opt_square_traverse(quota,e,border)
      end
    end
  end

  def wait_border_crossing(result)
    p "subscribing to pointer #{result.parent.inspect}"

    cio = CIO.first(:name=>result.parent.name)

    p "got #{cio.inspect}"
    Thread.new(cio.name,cio.x,cio.y,cio.width,cio.height) { |name,cx,cy,cw,ch|

      Redis.new.subscribe("juggernaut") do |on|
        on.message do |c,msg|
          r = MultiJson.decode msg
          if (r["channels"].include? "pointer")
            if /POS/.match(r["data"])
              z,x,y = /POS-(\d+),(\d+)/.match(r["data"]).to_a.map &:to_i
              p "data #{x},#{y} #{cx} #{cy} #{cw} #{ch}"

              if (x<cx or x>(cx+cw) or y<cy or y>(cy+ch))
                p "outside!!!"

                # Hacks start here

                aio = AIO.first(:name=>"0")
                aio.process_event(:suspend)

                arframe = AIO.first(:name=>"ar_frame")
                arframe.process_event(:present)
                p "after"

                Thread.stop
              end
            end
          end
        end
      end

    }
  end

end
