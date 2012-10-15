require "spec_helper"

require "em-spec/rspec"


describe 'AUI' do
  include EventMachine::SpecHelper

  before :all do
    connection_options = { :adapter => "redis"}
    DataMapper.setup(:default, connection_options)

    connect do |redis|
      require "MINT-core"
      require "support/redis_connector_monkey_patch"  # TODO dirty patch for a bug that i have not found :(

      DataMapper.finalize
      DataMapper::Model.raise_on_save_failure = true
    end
  end

  describe 'AIReference' do
    it 'should initialize with initiated' do
      connect do |redis|
        @a = MINT::AIReference.create(:name=>"ref")

        @a.states.should ==[:initialized]
        @a.new_states.should == [:initialized]
      end
    end

    it 'should refer to correct object' do
      connect do |redis|
        @a = MINT::AIReference.create(:name=>"ref",:refers=>"target")
        MINT::AIO.create(:name=>"target")

        @a.refers.name.should == "target"
      end
    end

    it 'should focus referred object' do
      connect do |redis|
        @a = MINT::AIReference.create(:name=>"ref",:refers=>"target")
        MINT::AIO.create(:name=>"target")

        #Todo ask Sebastian about the functioning of AIReference
        @a.process_event(:organize)
        @a.refers.process_event(:organize)
        @a.process_event(:present)
        @a.refers.process_event(:present)
        @a.process_event(:focus)
        @a.refers.states.should == [:focused]
      end
    end

    describe 'without refers' do

      it 'should return to defocused in case there is no referred object' do
        connect do |redis|
          @a = MINT::AIReference.create(:name=>"ref")
          @a.process_event(:organize)
          @a.process_event(:present)
          @a.process_event(:focus)
          @a.states.should == [:defocused]
        end
      end
    end

    describe 'with refers' do
      it 'should initialize with initiated and store reference correctly' do
        connect true do |redis|
          @a = MINT::AIReference.create(:name=>"ref")

          test_state_flow redis,"Interactor.AIO.test" ,%w(initialized)   do

            @r = MINT::AIO.create(:name => "test")
            @a = MINT::AIReference.create(:name=>"reference", :refers => "test")

            @a.states.should ==[:initialized]
            @a.new_states.should == [:initialized]
            @a.refers.name.should=="test"
          end
        end

      end

      it 'should forward focus' do
        connect true do |redis|

          test_state_flow redis,"Interactor.AIO.AIIN.AIINDiscrete.AIReference.reference" ,[["presenting", "defocused"],"focused", "defocused"]     do
            @r = MINT::AIO.create(:name => "test",:states=>[:defocused])
            @a = MINT::AIReference.create(:name=>"reference", :refers => "test",:states=>[:organized])
            @a.process_event :present
            @a.process_event :focus
            @a.states.should ==[:defocused]
            MINT::AIO.get("aui","test").states.should ==[:focused]
          end
        end

      end

    end

  end
end