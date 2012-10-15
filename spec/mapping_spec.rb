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

      class Logging
      def self.log(mapping,data)
        p "log: #{mapping} #{data}"
      end
      end
      DataMapper.finalize
      DataMapper::Model.raise_on_save_failure = true
    end
  end

  describe 'without Parser' do


    describe 'Sequential' do
      describe 'with EventAction' do
        it 'should fire event if all observations have been true' do
          connect true do |redis|
            o1 = Observation.new(:element =>"Interactor.InteractorTest",:name => "test_1", :states =>[:organized],:process=> :onchange)
            o2 = Observation.new(:element =>"Interactor.InteractorTest.InteractorTest_2",:name => "test_2", :states =>[:initialized], :result => "p",:process=> :continuous )
            a = EventAction.new(:event => :organize, :target => "p")
            m = MINT::SequentialMapping.new(:name=>"Interactor.InteractorTest Observation", :observations => [o1,o2],:actions =>[a])
            m.start

            test_state_flow redis,"Interactor.InteractorTest.InteractorTest_2.test_2" ,["initialized", "organized"] do
              test_1 = InteractorTest.create(:name => "test_1")
              test_1.process_event :organize
              test_2 = InteractorTest_2.create(:name => "test_2")
            end
          end
        end

        describe "sync mapping"    do
          it 'should support name selector and not observations for sync mappings' do
            connect true do |redis|
              o1 = Observation.new(:element =>"Interactor.AIO", :states =>[:presenting],:result=>"aio")
              o2 = NegationObservation.new(:element =>"Interactor.CIO", :name =>"aio.name" ,:states =>[:displaying], :result => "cio", :process => :continuous )
              a = EventAction.new(:event => :display, :target => "cio")
              m = MINT::SequentialMapping.new(:name=>"Sync CIO to display", :observations => [o1,o2],:actions =>[a])
              m.start

              test_state_flow redis,"Interactor.CIO.test" ,[["displaying", "init_js"],"displayed"] do
                aio = MINT::AIO.create(:name => "test", :states => [:organized])
                cio = MINT::CIO.create(:name => "test", :states=>[:positioned])
                aio.process_event :present

              end
            end
          end
          it 'should support not end up in cycles for sync mappings' do
            connect true do |redis|
              o1 = Observation.new(:element =>"Interactor.AIO", :states =>[:presenting],:result=>"aio",:process => :onchange)
              o2 = NegationObservation.new(:element =>"Interactor.CIO", :name =>"aio.name" ,:states =>[:displaying], :result => "cio",:process => :instant )
              a = EventAction.new(:event => :display, :target => "cio")
              m = MINT::SequentialMapping.new(:name=>"Sync CIO to display", :observations => [o1,o2],:actions =>[a])
              m.state_callback = Logging.method(:log)
              m.start

              o3 = Observation.new(:element =>"Interactor.CIO", :states =>[:displaying],:result=>"cio",:process => :onchange)
              o4 = NegationObservation.new(:element =>"Interactor.AIO", :name =>"cio.name" ,:states =>[:presenting], :result => "aio",:process => :instant)
              a1 = EventAction.new(:event => :present, :target => "aio")
              m1 = MINT::SequentialMapping.new(:name=>"Sync CIO display to AIO presenting", :observations => [o3,o4],:actions =>[a1])
              m1.state_callback = Logging.method(:log)
              m1.start

              test_state_flow redis,"Interactor.AIO.test" ,[["presenting", "defocused"]] do
                aio = MINT::AIO.create(:name => "test", :states => [:organized])
                cio = MINT::CIO.create(:name => "test", :states=>[:positioned])
                cio.process_event :display

              end
            end
          end
        end



      end
    end


    describe 'Complementary' do
      describe 'with EventAction' do
        it 'should fire event if the observation is true' do
          connect true do |redis|
            o = Observation.new(:element =>"Interactor.InteractorTest", :name => "test", :result => "p", :states =>[:initialized], :process=>"onchange")
            a = EventAction.new(:event => :organize,:target => "p")
            m = MINT::ComplementaryMapping.new(:name=>"Interactor.InteractorTest Observation", :observations => [o],:actions =>[a])
            m.start

            test_state_flow redis,"Interactor.InteractorTest.test" ,["initialized", "organized"] do
              @a = InteractorTest.create(:name => "test")
            end
          end
        end

        it 'should fire event if both observations are true' do
          connect true do |redis|
            o1 = Observation.new(:element =>"Interactor.InteractorTest",:name => "test_1", :states =>[:organized], :process=>"onchange")
            o2 = Observation.new(:element =>"Interactor.InteractorTest.InteractorTest_2",:name => "test_2", :states =>[:initialized], :result => "p",:process=>"instant")
            a = EventAction.new(:event => :organize, :target => "p")
            m = MINT::ComplementaryMapping.new(:name=>"Interactor.InteractorTest Observation", :observations => [o1,o2],:actions =>[a])
            m.start

            test_state_flow redis,"Interactor.InteractorTest.InteractorTest_2.test_2" ,["initialized", "organized"] do
              test_1 = InteractorTest.create(:name => "test_1")
              test_2 = InteractorTest_2.create(:name => "test_2")
              test_1.process_event :organize
            end
          end
        end

        it 'should handle a continuous observation' do
          pending "rethink if step 3 really should happen"
          connect true do |redis|
            o1 = Observation.new(:element =>"Interactor.InteractorTest.InteractorTest2",:name => "test", :states =>[:presenting], :result => "p",:process => :onchange)
            a = EventAction.new(:event => :step, :target => "p")
            m = MINT::ComplementaryMapping.new(:name=>"Interactor.InteractorTest Observation", :observations => [o1],:actions =>[a])
            m.start

            test_state_flow redis,"Interactor.InteractorTest.InteractorTest2.test" ,["initialized", ["presenting", "step1"],"step2","step3","initialized"] do
              test = InteractorTest2.create(:name => "test")
              test.process_event :present

            end

          end
        end

        it 'should handle a non continuous observation' do
          connect true do |redis|
            o1 = Observation.new(:element =>"Interactor.InteractorTest.InteractorTest2",:name => "test", :states =>[:presenting], :result => "p", :process=>"onchange")
            a = EventAction.new(:event => :step, :target => "p")
            m = MINT::ComplementaryMapping.new(:name=>"Interactor.InteractorTest Observation", :observations => [o1],:actions =>[a])
            m.start

            test_state_flow redis,"Interactor.InteractorTest.InteractorTest2.test" ,["initialized", ["presenting", "step1"],"step2"] do
              test = InteractorTest2.create(:name => "test")
              test.process_event :present

            end

          end
        end

      end

      describe 'with BackendAction' do
        it 'should call the Backend Action if observation is true' do
          connect true do |redis|
            b = InteractorTest.new
            o = Observation.new(:element =>"Interactor.InteractorTest",:name => "test", :states =>[:organized], :result => "c", :process=>"onchange")
            a = BackendAction.new(:call => b.method(:show_states), :parameter => "c")
            m = MINT::ComplementaryMapping.new(:name=>"BackendAction test",:observations => [o],:actions =>[a])
            m.start

            test_state_flow redis,"Interactor.InteractorTest.test" ,["initialized", "organized"] do
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
      <observation interactor="Interactor.InteractorTest" name="test" states="initialized" result="p" process="onchange"/>
    </observations>
    <actions>
      <event type="organize" target="p"/>
    </actions>
  </operator>

</mapping>
EOS
            m = parser.build_from_scxml_string scxml
            m.start

            test_state_flow redis,"Interactor.InteractorTest.test" ,["initialized", "organized"] do
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
  <operator type="sequential">
    <observations>
      <observation interactor="Interactor.InteractorTest" name="test_1" states="organized" process="onchange"/>
      <observation interactor="Interactor.InteractorTest.InteractorTest_2" name="test_2" states="initialized" process="instant" result="p"/>
    </observations>
    <actions>
      <event type="organize" target="p"/>
    </actions>
  </operator>

</mapping>
EOS
            m = parser.build_from_scxml_string scxml
            m.start

            test_state_flow redis,"Interactor.InteractorTest.InteractorTest_2.test_2" ,["initialized", "organized"] do
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

            test_state_flow redis,"Interactor.InteractorTest" ,["initialized", "organized"] do
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

            test_state_flow redis,"Interactor.InteractorTest" ,["initialized", "organized"] do
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