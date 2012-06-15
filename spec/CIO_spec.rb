require "spec_helper"

require "em-spec/rspec"

require "cui_helper"


describe 'CUI' do
  include EventMachine::SpecHelper

  before :all do
    connection_options = { :adapter => "redis"}
    DataMapper.setup(:default, connection_options)


    connect do |redis|
      require "MINT-core"

      DataMapper.finalize
      DataMapper::Model.raise_on_save_failure = true
    end
  end

  describe 'CIO' do

    it 'should accept and save user and device with position event' do
      pending "user and device still need to be defined - will be moved to AIO!!!"
      connect do |redis|
        require "MINT-core"

        DataMapper.finalize

        test_state_flow redis,"Interactor.CIO" ,%w(initialized positioning)

        MINT::CIO.create(:name => "center")
        @c = MINT::CIO.first

        @c.process_event_vars(:position,"testuser","testdevice").should ==[:positioning]
        @c = MINT::CIO.first

        @c.user.should =="testuser"
        @c.device.should == "testdevice"


      end
    end


    it 'should serialize to JSON' do
      require 'dm-serializer'
      # => { "id": 1, "name": "Berta" }
    end

    it 'should initialize with initiated' do
      connect do |redis|
        center = CUIHelper.create_structure

        center.states.should == [:initialized]
      end
    end

    it 'should transform to display state after sequence of position,calculate, ready events ' do
      connect do |redis|
        CUIHelper.create_structure
        center = MINT::CIO.first(:name => "center")
        center.process_event(:position).should ==[:positioning]
        center.process_event(:calculated).should ==[:positioned]
        center.process_event(:display).should ==[:displayed]
        center.states.should == [:displayed]
      end
    end



    describe "highlighting" do

      it 'should move highlight to up and down' do
        connect do |redis|
          center=CUIHelper.create_structure_w_highlighted
          center.process_event("up").should ==[:displayed]

          up = MINT::CIO.first(:name=>"up")
          up.states.should ==[:highlighted]

          up.process_event("down").should == [:displayed]
          MINT::CIO.first(:name=>"center").states.should ==[:highlighted]
        end
      end

      it 'should move highlight to left and right' do
        connect do |redis|
          center = CUIHelper.create_structure_w_highlighted
          center.process_event("left").should ==[:displayed]

          left = MINT::CIO.first(:name=>"left")
          left.states.should ==[:highlighted]

          left.process_event("right").should == [:displayed]
          MINT::CIO.first(:name=>"center").states.should ==[:highlighted]
        end
      end
    end

    describe "sync with AUI" do

      it 'should sync highlight movements to AUI' do
        connect do |redis|
          center = CUIHelper.scenario2
          center.process_event(:left).should ==[:displayed]
          MINT::AIO.first(:name=>"center").states.should ==[:defocused]
          MINT::AIO.first(:name=>"left").states.should ==[:focused]
          MINT::CIO.first(:name=>"left").states.should ==[:highlighted]
        end
      end

      it 'should sync AUI focus movements to CUI' do
        connect do |redis|
          center = CUIHelper.scenario2
          a_center = MINT::AIO.first(:name => "center")
          a_center.process_event("next").should ==[:defocused]
          MINT::AIO.first(:name=>"down").states.should ==[:focused]
          MINT::CIO.first(:name=>"center").states.should ==[:displayed]
          MINT::CIO.first(:name=>"down").states.should ==[:highlighted]
        end
      end

      it 'should calculate its minimum size' do
        connect do |redis|
          center = CUIHelper.scenario2
          center.text="Hello world!"
          center.calculateMinimumSize
          center.minwidth.should==77
          center.minheight.should==26
        end
      end


    end
    describe "layout calculation" do
      def checkSizes(cio,x,y,width,height)
              cio.x.should == x
              cio.y.should == y
              cio.width.should == width
              cio.height.should ==height
            end
      it "should calculate sizes for CIC" do
        connect do |redis|
          @solver = Cassowary::ClSimplexSolver.new

          CUIHelper.layout_setup
          a_parent = MINT::AIContainer.create(:name=>"parent", :children =>"left|right|up|down")

          parent_cic = MINT::CIC.create(:name =>"parent",:cols=>2,:rows=>2,:x=>0,:y=>0,:width=>800,:height=>600)

          parent_cic.calculate_container(@solver,10)

          checkSizes(MINT::CIO.first(:name=>"left"),10,10,385,285)
          checkSizes(MINT::CIO.first(:name=>"right"),405,10,385,285)
          checkSizes(MINT::CIO.first(:name=>"up"),10,305,385,285)
          checkSizes(MINT::CIO.first(:name=>"down"),405,305,385,285)
        end
      end

      it "should calculate sizes for nested CICs" do
        connect do |redis|
          @solver = Cassowary::ClSimplexSolver.new

          CUIHelper.layout_setup
          MINT::AIContainer.create(:name=>"top", :children =>"parent_left|parent_right")
          MINT::AIContainer.create(:name=>"parent_left", :children =>"left|right|up|down",:states =>[:organized] )
          MINT::AIContainer.create(:name=>"parent_right",:states =>[:organized])

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
      end

      it "should consider CIC definitions without column or row definition to be positioned vertically" do
        connect do |redis|
          @solver = Cassowary::ClSimplexSolver.new

          CUIHelper.layout_setup

          a_top = MINT::AIContainer.create(:name=>"top", :children =>"parent_left|parent_right")
          MINT::AIContainer.create(:name=>"parent_left", :children =>"left|right",:states =>[:organized])

          MINT::AIContainer.create(:name=>"parent_right",:states =>[:organized])

          top_cic = MINT::CIC.create(:name =>"top",:x=>0,:y=>0,:width=>800,:height=>800)
          parent_left_cic = MINT::CIC.create(:name =>"parent_left").save!
          parent_right_cic = MINT::CIC.create(:name =>"parent_right").save!

          top_cic.calculate_container(@solver,10)

          checkSizes(MINT::CIO.first(:name=>"parent_left"),10,10,780,385)
          checkSizes(MINT::CIO.first(:name=>"parent_right"),10,405,780,385)

          checkSizes(MINT::CIO.first(:name=>"left"),20,20,760,177)
          checkSizes(MINT::CIO.first(:name=>"right"),20,207,760,177)
        end
      end

      it "should create CIC definitions that are missing and position them vertically vertically" do
        connect do |redis|
          @solver = Cassowary::ClSimplexSolver.new

          CUIHelper.layout_setup


          a_top = MINT::AIContainer.create(:name=>"top", :children =>"parent_left|parent_right")
          MINT::AIContainer.create(:name=>"parent_left", :children =>"left|right",:states =>[:organized])

          MINT::AIContainer.create(:name=>"parent_right",:states =>[:organized])

          top_cic = MINT::CIC.create(:name =>"top",:x=>0,:y=>0,:width=>800,:height=>800)

          top_cic.calculate_container(@solver,10)

          checkSizes(MINT::CIO.first(:name=>"parent_left"),10,10,780,385)
          checkSizes(MINT::CIO.first(:name=>"parent_right"),10,405,780,385)

          checkSizes(MINT::CIO.first(:name=>"left"),20,20,760,177)
          checkSizes(MINT::CIO.first(:name=>"right"),20,207,760,177)
        end
      end

      it "should handle nested AIContainer definitions" do
        connect do |redis|
          solver = Cassowary::ClSimplexSolver.new

          CUIHelper.layout_setup

          CUIHelper.layout_scenario2(solver)

          checkSizes(MINT::CIO.first(:name=>"RecipeFilter_content"),20,305,760,275)
          MINT::AIO.first(:name=>"RecipeFilter_label").label.should=="Suchkriterien"
        end
      end

      it "should calculate the layer  level for nested containers" do
        connect do |redis|
          solver = Cassowary::ClSimplexSolver.new
          CUIHelper.layout_setup

          @test = CUIHelper.layout_scenario2(solver)

          @test.calculate_container(solver,10)

          MINT::CIO.first(:name=>"RecipeFilter_content").layer.should ==2
          MINT::CIO.first(:name=>"RecipeFilter_label").layer.should== 3
        end
      end



      it "should end up with all cios set to state  >positioned< after layout calculation" do
        connect do |redis|
          CUIHelper.layout_setup
          @solver = Cassowary::ClSimplexSolver.new

          a_top = MINT::AIContainer.create(:name=>"top",:states =>[:organized], :children =>"parent_left|parent_right")

          MINT::AIContainer.create(:name=>"parent_left", :children =>"left|right",:states =>[:organized])
          MINT::AIContainer.create(:name=>"parent_right",:states =>[:organized])

          top_cic = MINT::CIC.create(:name =>"top",:x=>0,:y=>0,:width=>800,:height=>800)
          parent_left_cic = MINT::CIC.create(:name =>"parent_left").save!
          parent_right_cic = MINT::CIC.create(:name =>"parent_right").save!

          top_cic.calculate_container(@solver,10)

          MINT::CIC.first(:name=>"top").states.should==[:positioned]
          MINT::CIC.first(:name=>"parent_left").states.should==[:positioned]
          MINT::CIC.first(:name=>"parent_right").states.should==[:positioned]
        end
      end

      it "should layout only elements that have not been calculated - case uncalculated leaf cios" do
        connect do |redis|
          CUIHelper.layout_setup
          @solver = Cassowary::ClSimplexSolver.new
          a_top = MINT::AIContainer.create(:name=>"top",:states =>[:organized], :children =>"parent_left|parent_right")

          MINT::AIContainer.create(:name=>"parent_left", :children =>"left|right",:states =>[:organized])
          MINT::AIContainer.create(:name=>"parent_right",:states =>[:organized])

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
      end

      it "should layout uncalculated parental elements based on calculated leaf cios" do
        pending("get the right container calculation working that has no children!")
        connect do |redis|
          CUIHelper.layout_setup
          @solver = Cassowary::ClSimplexSolver.new
          a_top = MINT::AIContainer.create(:name=>"top",:states =>[:organized], :children =>"parent_left|parent_right")

          MINT::AIContainer.create(:name=>"parent_left", :children =>"left|right",:states =>[:organized])
          MINT::AIContainer.create(:name=>"parent_right",:states =>[:organized])

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
      connect do |redis|

        a= MINT::CIO.create(:name=>"left_2x",:x=>1,:y =>1, :width=>390,:height =>800,:states => [:displayed], :highlightable => true)
        b= MINT::CIO.create(:name=>"right_2x",:x=>400,:y =>2, :width=>389,:height =>799,:states => [:displayed], :highlightable => true)

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
end
