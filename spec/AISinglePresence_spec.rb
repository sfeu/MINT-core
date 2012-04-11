require "spec_helper"

require "em-spec/rspec"



describe 'AUI' do
  include EventMachine::SpecHelper

  before :all do
    class ::AISinglePresenceHelper
      def self.create_data
        MINT::AISinglePresence.new(:name=>"a", :children =>[
            MINT::AIO.new(:name => "e1"),
            MINT::AIO.new(:name => "e2"),
            MINT::AIO.new(:name => "e3")
        ]).save

        @a = MINT::AISinglePresence.first
        @a
      end

    end
    connection_options = { :adapter => "redis"}
    DataMapper.setup(:default, connection_options)


    connect do |redis|
      require "MINT-core"

      DataMapper.finalize
      DataMapper::Model.raise_on_save_failure = true
    end
  end



  describe 'AISinglePresence' do
    it 'should initialize with initiated' do
      connect do |redis|
        @a = AISinglePresenceHelper.create_data
        @a.states.should ==[:initialized]
        @a.new_states.should == [:initialized]
      end
    end

    it 'should transform to organizing state ' do
      connect do |redis|
        @a = AISinglePresenceHelper.create_data
        @a.process_event(:organize).should ==[:organized]
        @a.states.should == [:organized]
        @a.new_states.should == [:organized]
      end
    end

    it 'should transform first child to presented if presented and rest to suspended' do
      connect do |redis|
        @a = AISinglePresenceHelper.create_data

        AUIControl.organize(@a,nil,0)
        # @a.process_event(:organize).should ==[:organized]
        @a.states.should == [:organized]
        @a.new_states.should == [:organized]
        @a.process_event(:present).should ==[:defocused]
        children = @a.children
        children[0].states.should == [:defocused]
        children[1].states.should == [:suspended]
        children[2].states.should == [:suspended]
      end
    end

    it 'should hide the other elements if a child is presented' do
      connect do |redis|
        @a = AISinglePresenceHelper.create_data

        AUIControl.organize(@a,nil,0)
        @a.process_event(:present).should == [:defocused]

        MINT::AIO.first(:name => "e1").states.should == [:defocused]
        MINT::AIO.first(:name => "e2").states.should == [:suspended]
        MINT::AIO.first(:name => "e3").states.should == [:suspended]

        e3 = MINT::AIO.first(:name => "e3")
        e3.states.should ==[:suspended]
        e3.process_event(:present).should == [:defocused]

        MINT::AIO.first(:name => "e1").states.should == [:suspended]
        MINT::AIO.first(:name => "e2").states.should == [:suspended]
        MINT::AIO.first(:name => "e3").states.should == [:defocused]

        e2 = MINT::AIO.first(:name => "e2")
        e2.states.should ==[:suspended]
        e2.process_event(:present).should == [:defocused]

        MINT::AIO.first(:name => "e1").states.should == [:suspended]
        MINT::AIO.first(:name => "e2").states.should == [:defocused]
        MINT::AIO.first(:name => "e3").states.should == [:suspended]
      end
    end

    it 'should hide the other elements if a child is presented (using next and prev events)' do
      connect do |redis|
        @a = AISinglePresenceHelper.create_data
        AUIControl.organize(@a,nil,0)
        @a.process_event(:present).should == [:defocused]

        MINT::AIO.first(:name => "e1").states.should == [:defocused]
        MINT::AIO.first(:name => "e2").states.should == [:suspended]
        MINT::AIO.first(:name => "e3").states.should == [:suspended]

        @a.process_event(:focus).should == [:waiting]
        @a.process_event(:enter).should == [:entered]
        @a.process_event(:next).should == [:entered]

        MINT::AIO.first(:name => "e1").states.should == [:suspended]
        MINT::AIO.first(:name => "e2").states.should == [:defocused]
        MINT::AIO.first(:name => "e3").states.should == [:suspended]

        @a.process_event(:prev).should == [:entered]

        MINT::AIO.first(:name => "e1").states.should == [:defocused]
        MINT::AIO.first(:name => "e2").states.should == [:suspended]
        MINT::AIO.first(:name => "e3").states.should == [:suspended]
      end
    end



  end
end
