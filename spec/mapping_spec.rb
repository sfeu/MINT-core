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
      include MINT

      class InteractorTest < MINT::Interactor

        def show_states c
          puts "States #{c['states']}"
        end

        def getSCXML
          "#{File.dirname(__FILE__)}/interactor_test.scxml"
        end
      end
      class InteractorTest_2 <InteractorTest
      end
      class InteractorTest2 <InteractorTest
        def getSCXML
          "#{File.dirname(__FILE__)}/interactor_test_2.scxml"
        end
      end


      DataMapper.finalize
      DataMapper::Model.raise_on_save_failure = true
    end
  end

  describe 'without Parser' do
    describe 'Complementary' do
      describe 'with EventAction' do
        it 'should fire event if the observation is true' do
          connect true do |redis|
            o = Observation.new(:element =>"Interactor.InteractorTest", :name => "test", :result => "p", :states =>[:initialized])
            a = EventAction.new(:event => :organize,:target => "p")
            m = MINT::ComplementaryMapping.new(:name=>"Interactor.InteractorTest Observation", :observations => [o],:actions =>[a])
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
            a = EventAction.new(:event => :organize, :target => "p")
            m = MINT::ComplementaryMapping.new(:name=>"Interactor.InteractorTest Observation", :observations => [o1,o2],:actions =>[a])
            m.start

            test_state_flow RedisConnector.sub,"Interactor.InteractorTest.InteractorTest_2" ,["initialized", "organized"] do
              test_1 = InteractorTest.create(:name => "test_1")
              test_2 = InteractorTest_2.create(:name => "test_2")
              test_1.process_event :organize
            end
          end
        end

        it 'should handle a continuous observation' do
          connect true do |redis|
            o1 = Observation.new(:element =>"Interactor.InteractorTest.InteractorTest2",:name => "test", :states =>[:presenting], :result => "p",:continuous=>true)
            a = EventAction.new(:event => :step, :target => "p")
            m = MINT::ComplementaryMapping.new(:name=>"Interactor.InteractorTest Observation", :observations => [o1],:actions =>[a])
            m.start

            test_state_flow RedisConnector.sub,"Interactor.InteractorTest.InteractorTest2" ,["initialized", ["presenting", "step1"],"step2","step3","initialized"] do
              test = InteractorTest2.create(:name => "test")
              test.process_event :present

            end

          end
        end

        it 'should handle a non continuous observation' do
          connect true do |redis|
            o1 = Observation.new(:element =>"Interactor.InteractorTest.InteractorTest2",:name => "test", :states =>[:presenting], :result => "p")
            a = EventAction.new(:event => :step, :target => "p")
            m = MINT::ComplementaryMapping.new(:name=>"Interactor.InteractorTest Observation", :observations => [o1],:actions =>[a])
            m.start

            test_state_flow RedisConnector.sub,"Interactor.InteractorTest.InteractorTest2" ,["initialized", ["presenting", "step1"],"step2"] do
              test = InteractorTest2.create(:name => "test")
              test.process_event :present

            end

          end
        end

      end

      describe 'with BindAction' do
        it 'should bind if both observation are true' do
          connect true do |redis|
            o1 = Observation.new(:element =>"Interactor.InteractorTest",:name => "test", :states =>[:organized])
            o2 = Observation.new(:element =>"Interactor.InteractorTest.InteractorTest_2",:name=>"test_2", :states =>[:presenting])
            a = BindAction.new(:elementIn => "Interactor.InteractorTest",:nameIn => "test", :attrIn =>"data",:attrOut=>"data",
                               :elementOut =>"Interactor.InteractorTest.InteractorTest_2", :nameOut=>"test_2" )
            m = MINT::ComplementaryMapping.new(:name => "BindAction test", :observations => [o1,o2],:actions =>[a])
            m.start

            test_state_flow RedisConnector.sub,"Interactor.InteractorTest" ,["initialized", "organized"] do
              test_1 = InteractorTest.create(:name => "test")
              test_2 = InteractorTest_2.create(:name => "test_2")
              test_1.process_event :organize
              test_2.process_event :organize
              test_2.process_event :present
            end
          end
        end

      end

      describe 'with BackendAction' do
        it 'should call the Backend Action if observation is true' do
          connect true do |redis|
            b = InteractorTest.new
            o = Observation.new(:element =>"Interactor.InteractorTest",:name => "test", :states =>[:organized], :result => "c")
            a = BackendAction.new(:call => b.method(:show_states), :parameter => "c")
            m = MINT::ComplementaryMapping.new(:name=>"BackendAction test",:observations => [o],:actions =>[a])
            m.start

            test_state_flow RedisConnector.sub,"Interactor.InteractorTest" ,["initialized", "organized"] do
              test = InteractorTest.create(:name => "test")
              test.process_event :organize
            end
          end
        end
      end
    end
  end


  describe 'with Parser' do
    describe 'Complementary' do
      describe 'with EventAction' do
        it 'should fire event if the observation is true' do
          connect true do |redis|
            parser = MINT::MappingParser.new
            scxml = <<EOS
<mapping name="Interactor.InteractorTest Observation" xmlns="http://www.multi-access.de"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://www.multi-access.de mint-mappings.xsd">
  <operator type="complementary">
    <observations>
      <observation interactor="Interactor.InteractorTest" name="test" states="initialized" result="p"/>
    </observations>
    <actions>
      <event type="organize" target="p"/>
    </actions>
  </operator>

</mapping>
EOS
            m = parser.build_from_scxml_string scxml
            m.start

            test_state_flow RedisConnector.sub,"Interactor.InteractorTest" ,["initialized", "organized"] do
              @a = InteractorTest.create(:name => "test")
            end
          end
        end

        it 'should fire event if both observations are true' do
          connect true do |redis|
            parser = MINT::MappingParser.new
            scxml = <<EOS
<mapping name="Interactor.InteractorTest Observation" xmlns="http://www.multi-access.de"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://www.multi-access.de mint-mappings.xsd">
  <operator type="complementary">
    <observations>
      <observation interactor="Interactor.InteractorTest" name="test_1" states="organized"/>
      <observation interactor="Interactor.InteractorTest.InteractorTest_2" name="test_2" states="initialized" result="p"/>
    </observations>
    <actions>
      <event type="organize" target="p"/>
    </actions>
  </operator>

</mapping>
EOS
            m = parser.build_from_scxml_string scxml
            m.start

            test_state_flow RedisConnector.sub,"Interactor.InteractorTest.InteractorTest_2" ,["initialized", "organized"] do
              test_1 = InteractorTest.create(:name => "test_1")
              test_2 = InteractorTest_2.create(:name => "test_2")
              test_1.process_event :organize
            end
          end
        end
      end

=begin
describe 'with BindAction' do
        it 'should bind if both observation are true' do
          connect true do |redis|
            o1 = Observation.new(:element =>"Interactor.InteractorTest",:name => "test", :states =>[:organized])
            o2 = Observation.new(:element =>"Interactor.InteractorTest.InteractorTest_2",:name=>"test_2", :states =>[:presenting])
            a = BindAction.new(:elementIn => "Interactor.InteractorTest",:nameIn => "test", :attrIn =>"data",:attrOut=>"data",
                               :elementOut =>"Interactor.InteractorTest.InteractorTest_2", :nameOut=>"test_2" )
            m = ComplementaryMapping.new(:name => "BindAction test", :observations => [o1,o2],:actions =>[a])
            m.start

            test_state_flow RedisConnector.sub,"Interactor.InteractorTest" ,["initialized", "organized"] do
              test_1 = InteractorTest.create(:name => "test")
              test_2 = InteractorTest_2.create(:name => "test_2")
              test_1.process_event :organize
              test_2.process_event :organize
              test_2.process_event :present
            end
          end
        end

      end

      describe 'with BackendAction' do
        it 'should call the Backend Action if observation is true' do
          connect true do |redis|
            b = InteractorTest.new
            o = Observation.new(:element =>"Interactor.InteractorTest",:name => "test", :states =>[:organized], :result => "c")
            a = BackendAction.new(:call => b.method(:show_states), :parameter => "c")
            m = ComplementaryMapping.new(:name=>"BackendAction test",:observations => [o],:actions =>[a])
            m.start

            test_state_flow RedisConnector.sub,"Interactor.InteractorTest" ,["initialized", "organized"] do
              test = InteractorTest.create(:name => "test")
              test.process_event :organize
            end
          end
        end
      end
=end
    end
  end

end