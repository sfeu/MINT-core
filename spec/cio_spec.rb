require "spec_helper"

describe 'CUI' do
  before :each do
    connection_options = { :adapter => "in_memory"}
    DataMapper.setup(:default, connection_options)
#    DataMapper.setup(:default, { :adapter => "rinda",:local =>Rinda::TupleSpace.new})

  end

  describe 'CIO' do
    before :each do
      @up = MINT::CIO.create(:name => "up")
      @down = MINT::CIO.create(:name => "down")
      @left = MINT::CIO.create(:name => "left")
      @right = MINT::CIO.create(:name => "right")
      @center = MINT::CIO.create(:name => "center",:left=>@left,:right =>@right,:up =>@up, :down=>@down)
      @down.up = @center
      @up.down  = @center
      @left.right = @center
      @right.left = @center
    end

    it 'should serialize to JSON' do
         require 'dm-serializer'
                     # => { "id": 1, "name": "Berta" }
       end

    it 'should initialize with initiated' do
      @center.states.should == [:initialized]
    end

    it 'should transform to display state after sequence of position,calculate, ready events ' do
      @center.process_event(:position).should ==[:positioning]
      @center.process_event(:calculated).should ==[:positioned]
      @center.process_event(:display).should ==[:displayed]
      @center.states.should == [:displayed]
       puts @center.to_json
    end



    describe "highlighting" do
      before :each do
        @up.states=[:displayed]
        @down.states=[:displayed]
        @left.states=[:displayed]
        @right.states=[:displayed]
        @center.states=[:highlighted]
      end

      it 'should move highlight to up and down' do
        @center.process_event("up").should ==[:displayed]
        @up.states.should ==[:highlighted]

        @up.process_event("down").should == [:displayed]
        @center.states.should ==[:highlighted]
      end

      it 'should move highlight to left and right' do
        @center.process_event("left").should ==[:displayed]
        @left.states.should ==[:highlighted]

        @left.process_event("right").should == [:displayed]
        @center.states.should ==[:highlighted]
      end
    end

    describe "sync with AUI" do
      before :each do

        @up.states=[:displayed]
        @down.states=[:displayed]
        @left.states=[:displayed]
        @right.states=[:displayed]
        @center.states=[:highlighted]

        @a_left = MINT::AIO.new(:name => "left",:states =>[:defocused])
        @a_left.save!

        @a_right = MINT::AIO.new(:name => "right",:states =>[:defocused])
        @a_right.save!
        @a_up = MINT::AIO.new(:name => "up",:states =>[:defocused])
        @a_up.save!
        @a_down = MINT::AIO.new(:name => "down",:states =>[:defocused])
        @a_down.save!
        @a_center = MINT::AIO.new(:name => "center",:states =>[:focused], :next =>@a_down)
        @a_center.save!

      end

      it 'should sync highlight movements to AUI' do
        @center.process_event(:left).should ==[:displayed]
        MINT::AIO.first(:name=>"center").states.should ==[:defocused]
        MINT::AIO.first(:name=>"left").states.should ==[:focused]
        @left.states.should ==[:highlighted]
      end

      it 'should sync AUI focus movements to CUI' do
        @center.save!
        @down.save!
        @a_center.process_event("next").should ==[:defocused]
        @a_down.states.should ==[:focused]
        MINT::CIO.first(:name=>"center").states.should ==[:displayed]
        MINT::CIO.first(:name=>"down").states.should ==[:highlighted]
      end

      it 'should calculate its minimum size' do
        @center.text="Hello world!"
        @center.calculateMinimumSize
        @center.minwidth.should==77
        @center.minheight.should==26
      end

      def checkSizes(cio,x,y,width,height)
        cio.x.should == x
        cio.y.should == y
        cio.width.should == width
        cio.height.should ==height
      end

      describe "layout calculation" do
        before :each do
          @solver = Cassowary::ClSimplexSolver.new

          @up.states=[:initialized]
          @down.states=[:initialized]
          @left.states=[:initialized]
          @right.states=[:initialized]


          @a_left.states=[:organized]
          @a_right.states=[:organized]
          @a_up.states=[:organized]
          @a_down.states=[:organized]
        end
        it "should calculate sizes for CIC" do
          a_parent = MINT::AIC.new(:name=>"parent", :childs =>[@a_left,@a_right,@a_up,@a_down])
          a_parent.save!

          parent_cic = MINT::CIC.create(:name =>"parent",:cols=>2,:rows=>2,:x=>0,:y=>0,:width=>800,:height=>600)

          parent_cic.calculate_container(@solver,10)

          checkSizes(MINT::CIO.first(:name=>"left"),10,10,385,285)
          checkSizes(MINT::CIO.first(:name=>"right"),405,10,385,285)
          checkSizes(MINT::CIO.first(:name=>"up"),10,305,385,285)
          checkSizes(MINT::CIO.first(:name=>"down"),405,305,385,285)
        end

        it "should calculate sizes for nested CICs" do
          a_top = MINT::AIC.new(:name=>"top", :childs =>[
              MINT::AIC.new(:name=>"parent_left", :childs =>[@a_left,@a_right,@a_up,@a_down],:states =>[:organized]),
              MINT::AIC.new(:name=>"parent_right",:states =>[:organized])
          ])
          a_top.save

          top_cic = MINT::CIC.create(:name =>"top",:cols=>2,:rows=>1,:x=>0,:y=>0,:width=>800,:height=>600)
          parent_left_cic = MINT::CIC.create(:name =>"parent_left",:cols=>2,:rows=>2)
          parent_right_cic = MINT::CIC.create(:name =>"parent_right",:cols=>2,:rows=>2)

          top_cic.calculate_container(@solver,10)

          checkSizes(MINT::CIO.first(:name=>"parent_left"),10,10,385,580)
          checkSizes(MINT::CIO.first(:name=>"parent_right"),405,10,385,580)

          checkSizes(MINT::CIO.first(:name=>"left"),20,20,177,275)
          checkSizes(MINT::CIO.first(:name=>"right"),207,20,177,275)
          checkSizes(MINT::CIO.first(:name=>"up"),20,305,177,275)
          checkSizes(MINT::CIO.first(:name=>"down"),207,305,177,275)

        end

        it "should consider CIC definitions without column or row definition to be positioned vertically" do

          a_top = MINT::AIC.new(:name=>"top", :childs =>[
              MINT::AIC.new(:name=>"parent_left", :childs =>[@a_left,@a_right],:states =>[:organized]),
              MINT::AIC.new(:name=>"parent_right",:states =>[:organized])
          ])
          a_top.save!

          top_cic = MINT::CIC.create(:name =>"top",:x=>0,:y=>0,:width=>800,:height=>800)
          parent_left_cic = MINT::CIC.create(:name =>"parent_left").save!
          parent_right_cic = MINT::CIC.create(:name =>"parent_right").save!

          top_cic.calculate_container(@solver,10)

          checkSizes(MINT::CIO.first(:name=>"parent_left"),10,10,780,385)
          checkSizes(MINT::CIO.first(:name=>"parent_right"),10,405,780,385)

          checkSizes(MINT::CIO.first(:name=>"left"),20,20,760,177)
          checkSizes(MINT::CIO.first(:name=>"right"),20,207,760,177)

        end

        it "should create CIC definitions that are missing and position them vertically vertically" do

          a_top = MINT::AIC.new(:name=>"top", :childs =>[
              MINT::AIC.new(:name=>"parent_left", :childs =>[@a_left,@a_right],:states =>[:organized]),
              MINT::AIC.new(:name=>"parent_right",:states =>[:organized])
          ])
          a_top.save!

          top_cic = MINT::CIC.create(:name =>"top",:x=>0,:y=>0,:width=>800,:height=>800)

          top_cic.calculate_container(@solver,10)

          checkSizes(MINT::CIO.first(:name=>"parent_left"),10,10,780,385)
          checkSizes(MINT::CIO.first(:name=>"parent_right"),10,405,780,385)

          checkSizes(MINT::CIO.first(:name=>"left"),20,20,760,177)
          checkSizes(MINT::CIO.first(:name=>"right"),20,207,760,177)

        end

        it "should handle nested AIC definitions" do

          MINT::AIC.new(:name=>"RecipeFinder_content",:states =>[:organized],
                        :childs =>[
                            MINT::AIC.new(:name=>"RecipeFilter",:states =>[:organized],
                                          :childs => [
                                              MINT::AIC.new(:name=>"RecipeFilter_description1",:states =>[:organized],
                                                            :childs =>[
                                                                MINT::AIReference.new(:name=>"RecipeFilter_label",:label=>"Suchkriterien",:states =>[:organized]),
                                                                MINT::AIOUTContext.new(:name=>"RecipeFilter_description",:states =>[:organized],:text=>"In diesem Feld können Sie mit genauen Angaben zu Ihrem Gericht-Wunsch die Suche nach Ihrem Rezeptvorschlag eingrenzen."),
                                                            ]),
                                              MINT::AIC.new(:name=>"RecipeFilter_content",:states =>[:organized])
                                          ])
                        ]).save!


          test = MINT::CIC.new( :name => "RecipeFinder_content", :rows => 1, :cols=> 1,:x=>0, :y=>0, :width =>800, :height => 600)
          test.save!

          test.calculate_container(@solver,10)

          checkSizes(MINT::CIO.first(:name=>"RecipeFilter_content"),20,305,760,275)
          MINT::AIO.first(:name=>"RecipeFilter_label").label.should=="Suchkriterien"
        end

        it "should calculate the layer  level for nested containers" do

          MINT::AIC.new(:name=>"RecipeFinder_content",:states =>[:organized],
                        :childs =>[
                            MINT::AIC.new(:name=>"RecipeFilter",:states =>[:organized],
                                          :childs => [
                                              MINT::AIC.new(:name=>"RecipeFilter_description1",:states =>[:organized],
                                                            :childs =>[
                                                                MINT::AIReference.new(:name=>"RecipeFilter_label",:states =>[:organized],:label=>"Suchkriterien"),
                                                                MINT::AIOUTContext.new(:name=>"RecipeFilter_description",:states =>[:organized],:text=>"In diesem Feld können Sie mit genauen Angaben zu Ihrem Gericht-Wunsch die Suche nach Ihrem Rezeptvorschlag eingrenzen."),
                                                            ]),
                                              MINT::AIC.new(:name=>"RecipeFilter_content",:states =>[:organized])
                                          ])
                        ]).save!


          test = MINT::CIC.new( :name => "RecipeFinder_content", :rows => 1, :cols=> 1,:x=>0, :y=>0, :width =>800, :height => 600)
          test.save!

          test.calculate_container(@solver,10)

          MINT::CIO.first(:name=>"RecipeFilter_content").layer.should ==2
          MINT::CIO.first(:name=>"RecipeFilter_label").layer.should== 3
        end



        it "should end up with all cios set to state  >positioned< after layout calculation" do
          @solver = Cassowary::ClSimplexSolver.new
          a_top = MINT::AIC.new(:name=>"top",:states =>[:organized], :childs =>[
              MINT::AIC.new(:name=>"parent_left", :childs =>[@a_left,@a_right],:states =>[:organized]),
              MINT::AIC.new(:name=>"parent_right",:states =>[:organized])
          ])
          a_top.save!

          top_cic = MINT::CIC.create(:name =>"top",:x=>0,:y=>0,:width=>800,:height=>800)
          parent_left_cic = MINT::CIC.create(:name =>"parent_left").save!
          parent_right_cic = MINT::CIC.create(:name =>"parent_right").save!

          top_cic.calculate_container(@solver,10)

          MINT::CIC.first(:name=>"top").states.should==[:positioned]
          MINT::CIC.first(:name=>"parent_left").states.should==[:positioned]
          MINT::CIC.first(:name=>"parent_right").states.should==[:positioned]
        end

        it "should layout only elements that have not been calculated - case uncalculated leaf cios" do
          @solver = Cassowary::ClSimplexSolver.new
          a_top = MINT::AIC.new(:name=>"top",:states =>[:organized], :childs =>[
              MINT::AIC.new(:name=>"parent_left",:states =>[:organized], :childs =>[@a_left,@a_right]),
              MINT::AIC.new(:name=>"parent_right",:states =>[:organized])
          ])
          a_top.save!

          top_cic = MINT::CIC.create(:name =>"top",:states=>[:positioned],:x=>0,:y=>0,:width=>800,:height=>800)
          parent_left_cic = MINT::CIC.create(:name =>"parent_left",:states=>[:positioned],:x=>10,:y=>10,:width=>300,:height=>800).save!
          parent_right_cic = MINT::CIC.create(:name =>"parent_right",:states=>[:positioned],:x=>310,:y=>10,:width=>470,:height=>800).save!

          top_cic.calculate_container(@solver,10)

          MINT::CIC.first(:name=>"parent_left").states.should==[:positioned]
          checkSizes(MINT::CIO.first(:name=>"parent_left"),10,10,300,800)
          checkSizes(MINT::CIO.first(:name=>"left"),20,20,280,385)
          checkSizes(MINT::CIO.first(:name=>"right"),20,415,280,385)

          MINT::CIO.first(:name=>"left").states.should==[:positioned]
          MINT::CIO.first(:name=>"right").states.should==[:positioned]
        end

        it "should layout uncalculated parental elements based on calculated leaf cios" do
         pending("get the right container calculation working that has no childs!")
          @solver = Cassowary::ClSimplexSolver.new
          a_top = MINT::AIC.new(:name=>"top",:states =>[:organized], :childs =>[
              MINT::AIC.new(:name=>"parent_left",:states =>[:organized], :childs =>[@a_left,@a_right]),
              MINT::AIC.new(:name=>"parent_right",:states =>[:organized])
          ])
          a_top.save!

          top_cic = MINT::CIC.create(:name =>"top",:x=>0,:y=>0,:width=>800,:height=>800)
          parent_left_cic = MINT::CIC.create(:name =>"parent_left").save!
          parent_right_cic = MINT::CIC.create(:name =>"parent_right").save!
          MINT::CIO.first(:name=>"left").update(:x =>20,:y=>20,:width=>280,:height=>385,:states=>[:positioned])
          MINT::CIO.first(:name=>"right").update(:x =>20,:y=>415,:width=>280,:height=>385,:states=>[:positioned])

          top_cic.calculate_position(nil,nil,@solver,0,10)

          checkSizes(MINT::CIO.first(:name=>"right"),20,415,280,385)
          checkSizes(MINT::CIO.first(:name=>"left"),20,20,280,385)

          MINT::CIO.first(:name=>"parent_left").states.should==[:positioned]
          MINT::CIO.first(:name=>"parent_right").states.should==[:positioned]

          checkSizes(MINT::CIO.first(:name=>"parent_left"),10,10,300,800) # results are wrong border missing!
          checkSizes(MINT::CIO.first(:name=>"parent_right"),10,10,0,0)
        end

      end
    end

  end

  describe 'mouse' do
    it "should highlight CIOs based on coordinates retrieved by mouse" do
       connection_options = { :adapter => "in_memory"}
    DataMapper.setup(:default, connection_options)
    #   DataMapper.setup(:default, { :adapter => "rinda",:local =>Rinda::TupleSpace.new})

      a= MINT::CIO.create(:name=>"left_2x",:x=>1,:y =>1, :width=>390,:height =>800,:states => [:displayed])
      b= MINT::CIO.create(:name=>"right_2x",:x=>400,:y =>2, :width=>389,:height =>799,:states => [:displayed])

      puts b.pos.Xvalue

      CUIControl.fill_active_cio_cache

      Result = Struct.new(:x, :y)

      CUIControl.find_cio_from_coordinates(Result.new(10,10))

      a = MINT::CIO.first(:name=>"left_2x")
       a.states.should==[:highlighted]
      MINT::CIO.first(:name=>"right_2x").states.should==[:displayed]

      CUIControl.find_cio_from_coordinates(Result.new(410,10))

      MINT::CIO.first(:name=>"left_2x").states.should==[:displayed]
      MINT::CIO.first(:name=>"right_2x").states.should==[:highlighted]

      CUIControl.find_cio_from_coordinates(Result.new(395,10))

      MINT::CIO.first(:name=>"left_2x").states.should==[:displayed]
      MINT::CIO.first(:name=>"right_2x").states.should==[:displayed]

    end
  end
end
