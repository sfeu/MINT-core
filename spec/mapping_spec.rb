require "spec_helper"

require "em-spec/rspec"


describe 'Mapping' do
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
      class InteractorTest_2 <InteractorTest
      end
      DataMapper.finalize
      DataMapper::Model.raise_on_save_failure = true
    end
  end

  describe 'Complementary' do
    it 'should fire event if the observation is true' do
      connect true do |redis|
        o = Observation.new(:element =>"Interactor.InteractorTest",:name => "test", :states =>[:initialized], :result => "p")
        a = EventAction.new(:event => :organize,:target => "p")
        m = ComplementaryMapping.new(:name=>"Interactor.InteractorTest Observation", :observations => [o],:actions =>[a])
        m.start

        test_state_flow RedisConnector.sub,"Interactor.InteractorTest" ,["initialized", "organized"] do
          @a = InteractorTest.create(:name => "test")
        end
      end
    end

    it 'should fire event if both observations are true' do
         connect true do |redis|
           o1 = Observation.new(:element =>"Interactor.InteractorTest",:name => "test_1", :states =>[:organized])
           o2 = Observation.new(:element =>"Interactor.InteractorTest.InteractorTest_2",:name => "test_2", :states =>[:initialized], :result => "p")
           a = EventAction.new(:event => :organize,:target => "p")
           m = ComplementaryMapping.new(:name=>"Interactor.InteractorTest Observation", :observations => [o1,o2],:actions =>[a])
           m.start

           test_state_flow RedisConnector.sub,"Interactor.InteractorTest.InteractorTest_2" ,["initialized", "organized"] do
             test_1 = InteractorTest.create(:name => "test_1")
             test_2 = InteractorTest_2.create(:name => "test_2")
             test_1.process_event :organize
           end
         end
       end
  end
end
