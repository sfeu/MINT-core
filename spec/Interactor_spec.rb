require "spec_helper"

require "em-spec/rspec"


describe 'Interactor' do
  include EventMachine::SpecHelper

  before :all do

    connection_options = { :adapter => "redis"}
    DataMapper.setup(:default, connection_options)

    connect do |redis|
      require "MINT-core"
      require "support/redis_connector_monkey_patch"  # TODO dirty patch for a bug that i have not found :(

      class InteractorTest < MINT::Interactor
        def getSCXML
          "#{File.dirname(__FILE__)}/interactor_test.scxml"
        end
      end

      DataMapper.finalize
      DataMapper::Model.raise_on_save_failure = true
    end
  end


  describe 'synchronized with RedisDB' do
    it 'should initialize with initiated' do
      connect do |redis|

        @a = InteractorTest.create(:name => "test")
        @a.states.should ==[:initialized]
        @a.abstract_states.should =="InteractorTest|root"

        @a.new_states.should == [:initialized]
      end

    end
    it 'should transform to organizing and presenting state' do
      connect  do |redis|
        @a = InteractorTest.create(:name => "test")
        @a.process_event(:organize)
        @a.abstract_states.should == "InteractorTest|root"
        @a.new_states.should == [:organized]
        @a.process_event(:present)
        @a.new_states.should == [:defocused, :in, :presenting, :f, :g]
        @a.abstract_states.should == "InteractorTest|root|presenting|f|g"
        @a.process_event(:out)
        @a.new_states.should == [:out]
        @a.abstract_states.should == "InteractorTest|root|presenting|f|g"
        @a.process_event(:focus)
        @a.new_states.should == [:focused]
        @a.abstract_states.should == "InteractorTest|root|presenting|f|g"
        @a.process_event(:suspend)
        @a.new_states.should == [:suspended]
        @a.abstract_states.should == "InteractorTest|root"

      end
    end
  end
  describe 'synchronized with Redis-PubSub' do
    it 'should initialize with initiated' do
      connect true do |redis|

        test_state_flow RedisConnector.redis,"Interactor.InteractorTest.test" ,%w(initialized) do

          @a = InteractorTest.create(:name => "test")
        end
      end

    end


    it 'should transform to organizing state for present action' do
      connect true do |redis|

        test_state_flow redis,"Interactor.InteractorTest.test" ,["initialized", "organized", ["presenting", "f", "g", "defocused", "in"],"out"] do
          @a = InteractorTest.create(:name => "test")
          @a.process_event(:organize)
          @a.process_event(:present)
          @a.process_event(:out)

        end

      end
    end



  end

end
