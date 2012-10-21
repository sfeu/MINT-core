module MINT
  class CIC < CIO
    property :rows, Integer
    property :cols, Integer

    def getSCXML
             "#{File.dirname(__FILE__)}/cic.scxml"
       end
    def getChildren
      aio = getAIO()
      children = aio.children.map &:name
      cios = []
      children.each do |name|
        cios << CIO.get(CIO.getModel(),name)
      end
      cios
    end

    def refresh_children
      p "i refresh children"
      getChildren.each do |cio|
        p "refreshing #{cio.name}"
        cio.process_event :refresh
      end
    end

    def calculate_position(parent_cic,elements,solver,i,b,layer=0)
      p "container #{self.name} #{b}"
      aic = AIContainer.first(:name=>self.name)
      elements = []


      if aic.children && aic.children.length>0

        calculateColsAndRows(aic.children.length)
        grid_hash= mda(self.rows,self.cols)

        aic.children.each_with_index do |e,i|
          cio = CIO.first(:name=>e.name)
          elements << cio
          if (not cio)
            cio = CIO.createCIOfromAIO(e,layer)
          end



          # Save the actual row,column, and  layer to the element
          cio.col =  i % self.cols
          cio.row =  i / self.cols
          cio.layer = layer+1


          cio.calculate_position(self,elements,solver,i,b,layer+1)
          grid_hash[cio.row][cio.col] = cio
          p "child #{cio.name} 1.positioning step"
        end

        if self.process_event("position")
          if parent_cic
            solver.AddConstraint(ClLinearEquation.new(self.pos.Y,ClLinearExpression.new(parent_cic.pos.Y.Value).Plus(ClLinearExpression.new(b))))
            solver.AddConstraint(ClLinearEquation.new(self.pos.X,ClLinearExpression.new(parent_cic.pos.X.Value).Plus(ClLinearExpression.new(b))))
          end


          # parent(height) = SUM(AllElementsOfColumn(c)(height))+((self.rows+1)*b)
          if (self.rows >0)
            self.cols.times do |c|
              solver.AddConstraint(ClLinearInequality.new(size.Y,CnGEQ,iterate_rows_of_column(grid_hash,c,self.rows-1).Plus(ClLinearExpression.new((self.rows+1)*b)),Cassowary.ClsStrong))
            end
          end

          # parent(width) = SUM(AllElementsOfRow(r)(width))+((self.cols+1)*b)
          if (self.cols>0)
            self.rows.times do |r|
              solver.AddConstraint(ClLinearInequality.new(size.X,CnGEQ,iterate_cols_of_row(grid_hash,r,self.cols-1).Plus(ClLinearExpression.new((self.cols+1)*b)),Cassowary.ClsStrong))
            end
          end
        else
          # fixed position
          p "CIC fixed#{self.inspect}"
          setFixedPositionConstraints(solver)
          setFixedSizeConstraints(solver)
        end

      else
        self.cio_calculate_position(parent_cic,elements,solver,i,b,layer)
      end

      self.process_event("calculated")
    end



    # elements array of elements from left to right and first to last row
    # cx, cy container position
    # ch,cw container size
    # rows and columns
    # b minimal border space between elements
    def calculate_container(solver,b,layer=0)

      #handle special cases where nr(elements) < self.cols * rows by overwriting rows and self.cols properties to fit elemnt amounts

      if self.process_event!("position")
     #   p "in positionion #{self.name}"
        self.layer = layer
        aic = AIContainer.first(:name=>self.name)

        elements_count = aic.children.length

        calculateColsAndRows(elements_count)

        # create grid with helper method
        self.rows= elements_count if (self.rows == nil)
        self.cols= 1 if (self.cols == nil)

        grid_hash= mda(self.rows,self.cols)
        #       p "hash #{ self.name} rows #{self.rows} cols #{self.cols}"

        ai_childs =  aic.children
        #      p aic.name
        elements=[]
        ai_childs.each_with_index do |e,i|
          if e.states == [:organized]

          cio = CIO.first(:name=>e.name)

          if (not cio)
            cio = CIO.createCIOfromAIO(e,layer)
          else
            cio.layer=layer+1
          end

          if (not cio.kind_of? MINT::CIC)
            cio.process_event!("position")
          end

          elements << cio

          cio.setMinimumSizeConstraints(solver)

          act_col = i % self.cols
          act_row = i / self.cols

      #    p "#{e.name} parent #{act_row} #{act_col}"

          grid_hash[act_row][act_col] = cio

          # Save the actual row and column of the element
          cio.col = act_col
          cio.row = act_row

          cio.setTableElementConstraints(solver,elements, self,act_col,act_row,i,b)

          if (cio.kind_of? MINT::CIC)
            cio.calculate_container(solver,b,layer+1)
          end
          end

        end

        # calculate navigation
       # calculate_gfx__navigation(grid_hash)
        save_grid(grid_hash)

        # Specify the parent container minimal width and height by summing ab all children widths and heights resp.

        # parent(height) = SUM(AllElementsOfColumn(c)(height))+((self.rows+1)*b)
        if (self.rows >0)
          self.cols.times do |c|
            solver.AddConstraint(ClLinearInequality.new(size.Y,CnGEQ,iterate_rows_of_column(grid_hash,c,self.rows-1).Plus(ClLinearExpression.new((self.rows+1)*b)),Cassowary.ClsStrong))
          end
        end

        # parent(width) = SUM(AllElementsOfRow(r)(width))+((self.cols+1)*b)
        if (self.cols>0)
          self.rows.times do |r|
            solver.AddConstraint(ClLinearInequality.new(size.X,CnGEQ,iterate_cols_of_row(grid_hash,r,self.cols-1).Plus(ClLinearExpression.new((self.cols+1)*b)),Cassowary.ClsStrong))
          end
        end

        elements.each { |e|
        # e.print
          if (not e.kind_of? MINT::CIC)
            e.process_event!("calculated")
          end
          e.save
        }
        self.process_event("calculated")
      else
        aic = AIContainer.first(:name=>name)
        elements = []
        aic.children.each_with_index do |e,i|
          cio = CIO.first(:name=>e.name)
          elements << cio
          if (not cio)
            cio = CIO.createCIOfromAIO(e,layer)
          end

          calculateColsAndRows(aic.children.length)

          # Save the actual row,column, and  layer to the element
          cio.col =  i % self.cols
          cio.row =  i / self.cols
          cio.layer = layer+1

          cio.calculate_position(self,elements,solver,i,b)

        end
      end
    end

    def mda(width, height)
      return Array.new(width){Array.new(height)}
    end

    def calculateColsAndRows(elements_count)
      if not self.cols and not self.rows
        self.rows = elements_count
        self.cols = 1
      end

      if (elements_count < self.cols*self.rows)
        if self.cols == 1
          self.rows = elements_count
        elsif self.rows ==1
          self.cols = elements_count
        else
          factor = elements_count / self.cols*self.rows
          self.cols = (self.cols*factor).round
          self.rows = (self.cols*factor).round
        end
      end
    end

    def calculate_gfx__navigation(array)
      array.each_with_index  do |row,r|
        row.each_with_index do |column,c|
          if not c==0
            # left and right in a table
            array[r][c-1].right = array[r][c]
            array[r][c].left = array[r][c-1]
        #    puts "left<>right: #{array[r][c-1].name} <>  #{array[r][c].name}"
          end
          if not r ==0
            # up and down in a table
            array[r-1][c].down = array[r][c]
            array[r][c].up = array[r-1][c]
         #   puts "up<>down: #{array[r-1][c].name} <>  #{array[r][c].name}"
          end
        end
      end
    end

    def save_grid(array)
      array.each_with_index  do |row,r|
        row.each_with_index do |column,c|
          array[r][c].save
        end
      end
    end

    # Iterates over all columns of one row that is set by #row_nr
    #
    # @param array the two dimensional array that should be iterated
    # @param row_nr the index of the row that should be used for iteration
    # @param index the highest index of a column that shoul be iterated (the iteration starts with this index and iterates backwards until 0.
    # @return [CLinearExpression] a Plus composed linear expressions with all variables
    #
    def iterate_cols_of_row(array,row_nr,index)
      if (index>0)
        return ClLinearExpression.new(array[row_nr][index].size.X).Plus(iterate_cols_of_row(array,row_nr,index-1))
      else
        return ClLinearExpression.new(array[row_nr][index].size.X)
      end
    end

    def iterate_rows_of_column(array,col_nr,index)
      begin

        if (index>0)
          return ClLinearExpression.new(array[index][col_nr].size.Y).Plus(iterate_rows_of_column(array,col_nr,index-1))
        else
          return ClLinearExpression.new(array[index][col_nr].size.Y)
        end
      rescue NoMethodError
        p "rescue with index #{index} and col_nr #{col_nr}"
      end
    end
  end
end