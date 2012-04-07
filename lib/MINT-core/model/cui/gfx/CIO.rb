module MINT
  class CIO_sync_callback
    def sync_aio_to_focused
      true
    end

    def sync_aio_to_presented
      true
    end
    def sync_aio_to_defocus
      true
    end

    def sync_aio_to_suspended
          true
        end

  end

  class CIO < Interactor
    include Cassowary

#    has 1, :up, self,
#        :parent_key => [ :id ],       # in the remote model (Blog)
#        :child_key  => [ :up_id ]  # local to this model (Post)
#    has 1,  :down, self,
#        :parent_key => [ :id ],       # in the remote model (Blog)
#        :child_key  => [ :down_id ]  # local to this model (Post)
#    has 1, :left, self,
#        :parent_key => [ :id ],       # in the remote model (Blog)
#        :child_key  => [ :left_id ]  # local to this model (Post)
#    has 1,  :right, self,
#        :parent_key => [ :id ],       # in the remote model (Blog)
#        :child_key  => [ :right_id ]  # local to this model (Post)

    property :text,     Text,   :lazy => false
    property :fontname,     String, :default  => "Helvetica"
    property :fontsize,     Integer, :default  => 13
    property :minwidth, Integer
    property :minheight, Integer
    property :minspace, Integer
    property :optspace, Integer
    property :width, Integer
    property :height, Integer
    property :x,  Integer
    property :y, Integer
    property :layer, Integer
    property :row, Integer
    property :col,Integer
    property :device, String
    property :user, String


#    before :create, :recover_statemachine

    before :create, :initialize_points
#    before :update,  :initialize_points
#    before :save!, :store_calculated_values_in_model
#    before :save, :store_calculated_values_in_model

    before :update!, :initialize_points
    public

    PUBLISH_ATTRIBUTES += [:x,:y,:width,:height]

    def initialize_points
      @pos = Cassowary::ClPoint.new()
      if (self.x and self.y)
        @pos = Cassowary::ClPoint.new(self.x,self.y)
      end
      @size = Cassowary::ClPoint.new()
      if (self.width and self.height)
        @size = Cassowary::ClPoint.new(self.width, self.height)
      elsif (self.minwidth and self.minheight)
        @size = Cassowary::ClPoint.new(self.minwidth, self.minheight)
      end
      true
    end

    def store_calculated_values_in_model

      attribute_set(:x,pos.Xvalue)
      attribute_set(:y,pos.Yvalue)
      attribute_set(:width,size.Xvalue)
      attribute_set(:height,size.Yvalue)

    end

    def pos(x=-1,y=-1)
      if (x > -1 and y> -1)
        @pos = Cassowary::ClPoint.new(x,y)
      elsif not @pos
        #if not @pos
        @pos = Cassowary::ClPoint.new

        if (attribute_get(:x) and attribute_get(:y))
          @pos = Cassowary::ClPoint.new(attribute_get(:x),attribute_get(:y))
        end
      end
      return @pos
    end

    def size(width=-1,height=-1)
      if (width > -1 and height> -1)
        @size = Cassowary::ClPoint.new(with,height)
      elsif not @size
        #if not @size
        @size = Cassowary::ClPoint.new
        if (attribute_get(:width) and attribute_get(:height))
          @size = Cassowary::ClPoint.new(attribute_get(:width), attribute_get(:height))
        elsif (attribute_get(:minwidth) and attribute_get(:minheight))
          @size = Cassowary::ClPoint.new(attribute_get(:minwidth), attribute_get(:minheight))
        end
      end
      return @size
    end

    def calculateMinimumSize(border = 5)
      if text

        label = Magick::Draw.new
        label.font = fontname
        label.text_antialias(true)
        label.font_style=Magick::NormalStyle
        label.font_weight=Magick::NormalWeight
        label.gravity=Magick::CenterGravity
        label.text(0,0,text)
        label.pointsize = fontsize
        metrics = label.get_type_metrics(text)

        self.minheight=metrics.height+2*border
        self.minwidth=metrics.width+2*border
      end
    end

    def calculate_position(parent_cic,elements,solver,i,b,layer =0)
      if self.process_event("position")
        p "cio #{self.inspect} parent #{parent_cic.inspect}"
        self.layer=layer
        setMinimumSizeConstraints(solver)

        setTableElementConstraints(solver,elements,parent_cic,self.col,self.row,i,b) if elements and elements.length>0
        self.process_event("calculated")
      else
        p "cio fixed#{self.inspect}"
        setFixedPositionConstraints(solver)
        setFixedSizeConstraints(solver)
      end

    end

    alias :cio_calculate_position :calculate_position

    def setFixedPositionConstraints(solver)
      solver.AddConstraint(ClLinearEquation.new(self.pos.X,ClLinearExpression.new(self.pos.X.Value),Cassowary.ClsStrong))
      solver.AddConstraint(ClLinearEquation.new(self.pos.Y,ClLinearExpression.new(self.pos.Y.Value),Cassowary.ClsStrong))
    end

    def setFixedSizeConstraints(solver)
      solver.AddConstraint(ClLinearEquation.new(self.size.X,ClLinearExpression.new(self.size.X.Value),Cassowary.ClsStrong))
      solver.AddConstraint(ClLinearEquation.new(self.size.Y,ClLinearExpression.new(self.size.Y.Value),Cassowary.ClsStrong))
    end

    def setMinimumSizeConstraints(solver)
      # p "l11"
      # take care of generate only positive values for height,width, x,y
      # p "#{name} -calculating>#{self.name}"
      # Consider minimum Sizes
      if self.minwidth
        solver.AddConstraint(ClLinearInequality.new(self.size.X,CnGEQ,ClLinearExpression.new(self.minwidth),Cassowary.ClsStrong))
      else
        solver.AddConstraint(ClLinearInequality.new(self.size.X,CnGEQ,ClLinearExpression.new(0),Cassowary.ClsStrong))
      end
      if self.minheight
        solver.AddConstraint(ClLinearInequality.new(self.size.Y,CnGEQ,ClLinearExpression.new(self.minheight),Cassowary.ClsStrong))
      else
        solver.AddConstraint(ClLinearInequality.new(self.size.Y,CnGEQ,ClLinearExpression.new(0),Cassowary.ClsStrong))
      end

      #      solver.AddConstraint(ClLinearInequality.new(self.pos.X,CnGEQ,ClLinearExpression.new(parent.pos.X),Cassowary.ClsStrong))
      #     solver.AddConstraint(ClLinearInequality.new(self.pos.Y,CnGEQ,ClLinearExpression.new(parent.pos.Y),Cassowary.ClsStrong))

    end

    def setTableElementConstraints(solver,elements, cic,act_col,act_row,i,b)
      total_cols = cic.cols
      total_rows = cic.rows

      if (act_col == 0)
        solver.AddConstraint(ClLinearEquation.new(self.pos.X,ClLinearExpression.new(cic.pos.X.Value).Plus(ClLinearExpression.new(b)),Cassowary.ClsStrong))
      else
        # e(x) = e-1(x)+e-1(width)+b
        solver.AddConstraint(ClLinearEquation.new(self.pos.X,ClLinearExpression.new(elements[i-1].pos.X.Value).Plus(ClLinearExpression.new(elements[i-1].size.X)).Plus(ClLinearExpression.new(b))))
      end

      # Y coordinate handling for first row
      if (i<total_cols)
        solver.AddConstraint(ClLinearEquation.new(self.pos.Y,ClLinearExpression.new(cic.pos.Y.Value).Plus(ClLinearExpression.new(b))))
      else
        solver.AddConstraint(ClLinearEquation.new(self.pos.Y,ClLinearExpression.new(elements[i-total_cols].pos.Y.Value).Plus(ClLinearExpression.new(elements[i-total_cols].size.Y)).Plus(ClLinearExpression.new(b))))
      end


      # maximize sizes
      #e(width)=c(width)/total_cols - ((total_cols+1)*b)/total_cols
      solver.AddConstraint(ClLinearEquation.new(self.size.X,ClLinearExpression.new(
          cic.size.X.Value).Divide(total_cols).Minus(ClLinearExpression.new(((total_cols+1)*b)/total_cols)),Cassowary.ClsWeak
                           ))

      #       solver.AddConstraint(ClLinearInequality.new(self.size.X,CnLEQ,ClLinearExpression.new(parent.size.X),Cassowary.ClsStrong))
      #e(height)= c(height)/total_rows - ((total_rows+1)*b)/total_rows
      solver.AddConstraint(ClLinearEquation.new(self.size.Y,ClLinearExpression.new(
          cic.size.Y.Value).Divide(total_rows).Minus(ClLinearExpression.new(((total_rows+1)*b)/total_rows)),Cassowary.ClsWeak
                           ))
      #      solver.AddConstraint(ClLinearInequality.new(e.size.Y,CnLEQ,ClLinearExpression.new(),Cassowary.ClsStrong))

      # relative size to the parent: e.size.X*e.size.Y/parent.size.X*parent.size.Y=e.minspace/parent.minspace
      #     if (parent.minspace and e.minspace and parent.minspace>0 and e.minspace>0)
      #   solver.AddConstraint(ClLinearEquation.new(e.size.Y,ClLinearExpression.new(parent.size.Y).Times(e.minspace/parent.minspace),Cassowary.ClsWeak
      #                                          ))

      #   solver.AddConstraint(ClLinearEquation.new(e.size.X,ClLinearExpression.new(parent.size.X).Times(e.minspace/parent.minspace),Cassowary.ClsWeak
      ###                                           ))
      # end

    end
    def CIO.createCIOfromAIO(e,layer)
      p "creating CIO for #{e.class}"
      case e.class.name
        when "MINT::AIC","MINT::AISinglePresence"
          aic = AIC.first(:name=>e.name)           # TODO: if its not retrieved again, childs.length returns 0!

          elements_count = aic.childs.length
          elements_count = 1 if elements_count== 0
          cio = CIC.create(:name=>e.name,:cols=>1,:rows=>elements_count,:layer =>layer+1)


          p "create #{e.name} rows: #{elements_count}"
        when "MINT::AIMultiChoice"
          cio = CheckBoxGroup.create(:name=>e.name,:layer =>layer+1)
        when "MINT::AISingleChoice"
          cio = RadioButtonGroup.create(:name=>e.name,:layer =>layer+1)
        when "MINT::AIMultiChoiceElement"
          cio = CheckBox.create(:name=>e.name,:layer =>layer+1)
        when "MINT::AISingleChoiceElement"
          cio = RadioButton.create(:name=>e.name,:layer =>layer+1)
        when "MINT::AIOUTContext"
          cio = BasicText.create(:name=>e.name,:layer =>layer+1)
        when "MINT::AIINReference"
          cio = Label.create(:name=>e.name,:layer =>layer+1)
        when "MINT::AICommand"
          cio = Button.create(:name=>e.name,:layer =>layer+1)
        else
          cio = CIO.create(:name=>e.name,:layer =>layer+1)

      end
      p "Created #{cio.inspect}"
      return cio
    end

    def initialize_statemachine
      if @statemachine.nil?

        @statemachine = Statemachine.build do

          superstate :CIO do
            trans :initialized,:position,:positioning, Proc.new { |user = nil,device =nil|
                self.user =user if user;
                self.device=device if device;
                true
            }
            trans :positioning,:calculated,:positioned, :store_calculated_values_in_model
            trans :positioned, :display, :presenting
            trans :disabled, :hide, :hidden
            trans :hidden,:display, :presenting

            state :hidden do
              on_entry :sync_aio_to_suspended
            end

            superstate :presenting do
              on_entry :sync_aio_to_presented

              state :displayed do
                on_entry :sync_aio_to_defocus
              end

              state :highlighted  do
                on_entry :sync_aio_to_focused
              end

              trans :displayed, :highlight, :highlighted
              #trans :displayed, :display, :displayed # a display request can be issued several times even if the object is already displayed (in case of refresh or multimple presentations
              #trans :highlighted, :display, :highlighted # this is because display requests should not change the highlighting
              trans :highlighted,:unhighlight, :displayed
              trans :highlighted, :up, :displayed, :highlight_up
              trans :highlighted, :down, :displayed, :highlight_down
              trans :highlighted, :left, :displayed, :highlight_left
              trans :highlighted, :right, :displayed, :highlight_right

              event :disable, :disabled
              event :hide, :hidden

            end
          end
        end
      end
    end


     def sync_event(event)
      process_event(event, CIO_sync_callback.new)
     end

    # callbacks

    def  highlight_up
      if (self.up)
        self.up.process_event("highlight")
      else
        return nil # TODO not working, find abbruchbedingung!!!
      end
    end

    def  highlight_down
      if (self.down)
        self.down.process_event("highlight")
      else
        return nil # TODO not working, find abbruchbedingung!!!
      end
    end

    def  highlight_left
      if (self.left)
        self.left.process_event("highlight")
      else
        return nil # TODO not working, find abbruchbedingung!!!
      end
    end

    def  highlight_right
      if (self.right)
        self.right.process_event("highlight")
      else
        return nil # TODO not working, find abbruchbedingung!!!
      end
    end


    def sync_aio_to_presented
      aio =  MINT::AIO.first(:name=>self.name)
       if (aio and not aio.is_in? :presenting)
        aio.sync_event(:present)
       end
      true
    end


    def sync_aio_to_defocus
      aio =  MINT::AIO.first(:name=>self.name)
       if (aio and not aio.is_in? :defocused)
         aio.sync_event(:defocus)
       end
      true
    end

    def sync_aio_to_focused
      aio =  MINT::AIO.first(:name=>self.name)
       if (aio and not aio.is_in? :focused)
        aio.sync_event(:focus)
       end
      true
    end

    def sync_aio_to_suspended
          aio =  MINT::AIO.first(:name=>self.name)
           if (aio and not aio.is_in? :suspended)
            aio.sync_event(:suspend)
           end
          true
        end



    def print
      puts "\"#{self.name}\",#{pos.Xvalue}, #{pos.Yvalue}, #{size.Xvalue}, #{size.Yvalue}"
    end

  end
end