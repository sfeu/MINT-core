require "spec_helper"

require "em-spec/rspec"


describe 'AUI' do
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

  describe 'AIReference' do
    it 'should initialize with initiated' do
      @a.states.should ==[:initialized]
      @a.new_states.should == [:initialized]
    end
    it 'should refer to correct object' do
      @a.refers.name.should == "target"
    end

    it 'should focus referred object' do
      #Todo ask Sebastian about the functioning of AIReference
      @a.process_event(:organize)
      @a.refers.process_event(:organize)
      @a.process_event(:present)
      @a.refers.process_event(:present)
      @a.process_event(:focus)
      @a.refers.states.should == [:focused]
    end

  end

  describe 'AIReference without refers' do
    before :each do
      connection_options = { :adapter => "in_memory"}
      DataMapper.setup(:default, connection_options)
      #    DataMapper.setup(:default, { :adapter => "rinda",:local =>Rinda::TupleSpace.new})
      MINT::AIReference.new(:name=>"ref").save

      @a = MINT::AIReference.first
    end
    it 'should return to defocused in case there is no referred object' do
      @a.process_event(:organize)
      @a.process_event(:present)
      @a.process_event(:focus)
      @a.states.should == [:defocused]
    end



  describe 'AIReference' do
    it 'should initialize with initiated and store reference correctly' do
      connect(true) do |redis|

        test_state_flow redis,"Element.AIO" ,%w(initialized)

        @r = MINT2::AIO.create(:name => "test")
        @a = MINT2::AIReference.create(:name=>"reference", :refers => "test")

        @a.states.should ==[:initialized]
        @a.new_states.should == [:initialized]
        @a.refers.name.should=="test"
      end

    end

    it 'should forward focus' do
      connect(true) do |redis|

       test_state_flow redis,"Element.AIO.AIIN.AIINDiscrete.AIReference" ,%w(defocused defocused)
       # test_state_flow redis,"Element.AIO" ,%w(focused focused)

        @r = MINT2::AIO.create(:name => "test",:states=>[:defocused])
        @a = MINT2::AIReference.create(:name=>"reference", :refers => "test",:states=>[:defocused])

        @a.process_event :focus
        @a.states.should ==[:defocused]
        MINT2::AIO.get("aui","test").states.should ==[:focused]

      end

    end

  end

end
