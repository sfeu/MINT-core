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
      class Logging
        def self.log(mapping,data)
          p "log: #{mapping} #{data}"
        end
      end
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



  end

  describe 'mouse' do
    it "should highlight CIOs based on coordinates retrieved by mouse" do
      connect do |redis|

        MINT::AIO.create(:name=>"left_2x",:states =>[:presented])
        a= MINT::CIO.create(:name=>"left_2x",:x=>1,:y =>1, :width=>390,:height =>800,:states => [:displayed], :highlightable => true)
        MINT::AIO.create(:name=>"right_2x",:states =>[:presented])
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
