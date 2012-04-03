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
