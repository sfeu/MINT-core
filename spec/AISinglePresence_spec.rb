require "spec_helper"

require "em-spec/rspec"



describe 'AUI' do
  include EventMachine::SpecHelper

  before :all do
    class ::AISinglePresenceHelper
      def self.create_data
        MINT::AISinglePresence.create(:name=>"a", :children =>"e1|e2|e3")

        MINT::AIO.create(:name => "e1",:parent=>"a")
        MINT::AIO.create(:name => "e2",:parent=>"a")
        MINT::AIO.create(:name => "e3",:parent=>"a")

        @a = MINT::AISinglePresence.first
        @a
      end

    end
    connection_options = { :adapter => "redis"}
    DataMapper.setup(:default, connection_options)


    connect do |redis|
      require "MINT-core"
      require "support/redis_connector_monkey_patch"  # TODO dirty patch for a bug that i have not found :(

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
      connect true do |redis|
        # Sync AIO to defocused
        parser = MINT::MappingParser.new
        m = parser.build_from_scxml File.dirname(__FILE__) +"/../lib/MINT-core/model/mim/aisinglepresence_present_to_child_present.xml"
        m.start


        check_result = Proc.new {
          MINT::AIO.first(:name=>"e1").states.should ==[:defocused]
          MINT::AIO.first(:name=>"e2").states.should ==[:suspended]
          MINT::AIO.first(:name=>"e3").states.should ==[:suspended]

          done
        }

        test_complex_state_flow_w_name redis,[["Interactor.AIO.AIOUT.AIContainer.AISinglePresence","a" ,["initialized","organized",["presenting", "wait_for_children"],"children_finished","defocused"]],["Interactor.AIO","e1" ,["initialized","organized",["presenting", "defocused"]]]],check_result do  |count|
          @a = AISinglePresenceHelper.create_data

          AUIControl.organize(@a,nil,0)
          # @a.process_event(:organize).should ==[:organized]
          @a.states.should == [:organized]
          @a.new_states.should == [:organized]
          @a.process_event(:present).should ==[:wait_for_children]

        end
      end
    end

    it 'should hide the other elements if a child is presented using present' do
      pending "requires child to inform parent about presenting"
      connect true do |redis|
        # Sync AIO to defocused
        parser = MINT::MappingParser.new
        m = parser.build_from_scxml File.dirname(__FILE__) +"/../lib/MINT-core/model/mim/aisinglepresence_present_to_child_present.xml"
        m.start


        check_result = Proc.new {
          MINT::AIO.first(:name => "e1").states.should == [:suspended]
          MINT::AIO.first(:name => "e2").states.should == [:defocused]
          MINT::AIO.first(:name => "e3").states.should == [:suspended]

          done
        }

        test_complex_state_flow_w_name redis,[["Interactor.AIO","e1" ,["initialized","organized",["presenting", "defocused"],"suspended"]]],check_result do  |count|
          @a = AISinglePresenceHelper.create_data

          AUIControl.organize(@a,nil,0)
          @a.process_event(:present).should == [:wait_for_children]

          e3 = MINT::AIO.first(:name => "e3")
          e3.process_event(:present).should == [:defocused]
          e2 = MINT::AIO.first(:name => "e2")
          e2.process_event(:present).should == [:defocused]
        end
      end

    end

    it 'should permit navigation before the first child ' do
      connect true do |redis|
        # Sync AIO to defocused
        parser = MINT::MappingParser.new
        m = parser.build_from_scxml File.dirname(__FILE__) +"/../lib/MINT-core/model/mim/aisinglepresence_present_to_child_present.xml"
        m.start


        check_result = Proc.new {
          @a = MINT::AISinglePresence.first
          @a.process_event :focus
          @a.process_event :enter
          @a.process_event :next
          MINT::AIO.first(:name => "e2").states.should == [:defocused]

          @a.process_event :prev
          MINT::AIO.first(:name => "e2").states.should == [:suspended]
          MINT::AIO.first(:name => "e1").states.should == [:defocused]

          @a.process_event :prev
          MINT::AIO.first(:name => "e2").states.should == [:suspended]
          MINT::AIO.first(:name => "e1").states.should == [:defocused]

          @a.process_event :next
          MINT::AIO.first(:name => "e1").states.should == [:suspended]
          MINT::AIO.first(:name => "e2").states.should == [:defocused]
          done
        }

        test_complex_state_flow_w_name redis,[["Interactor.AIO.AIOUT.AIContainer.AISinglePresence","a" ,["initialized","organized",["presenting", "wait_for_children"],"children_finished","defocused"]]],check_result do  |count|
          @a = AISinglePresenceHelper.create_data

          AUIControl.organize(@a,nil,0)
          # @a.process_event(:organize).should ==[:organized]
          @a.states.should == [:organized]
          @a.new_states.should == [:organized]
          @a.process_event(:present).should ==[:wait_for_children]

        end
      end

    end


    it 'should hide the other elements if a child is presented with next and prev events' do
      connect true do |redis|
        # Sync AIO to defocused
        parser = MINT::MappingParser.new
        m = parser.build_from_scxml File.dirname(__FILE__) +"/../lib/MINT-core/model/mim/aisinglepresence_present_to_child_present.xml"
        m.start

        check_result2 = Proc.new {
          MINT::AIO.first(:name => "e1").states.should == [:defocused]
          MINT::AIO.first(:name => "e2").states.should == [:suspended]
          MINT::AISinglePresence.first(:name => "a").active_child == "e1"
          done
        }

        check_result = Proc.new {
          redis.pubsub.unsubscribe("Interactor.AIO.AIOUT.AIContainer.AISinglePresence")

          a = MINT::AISinglePresence.first(:name => "a")
          a.process_event(:focus).should == [:waiting]

          test_complex_state_flow_w_name redis,[["Interactor.AIO","e1" ,["suspended",["presenting", "defocused"]]],["Interactor.AIO","e2" ,[["presenting", "defocused"],"suspended"]]],check_result2 do  |count|
            a.process_event(:enter).should == [:entered]
            a.process_event(:next).should == [:entered]
            a.process_event(:prev).should == [:entered]
          end
        }

        test_complex_state_flow_w_name redis,[["Interactor.AIO.AIOUT.AIContainer.AISinglePresence","a" ,["initialized","organized",["presenting", "wait_for_children"],"children_finished","defocused"]]],check_result do  |count|
          @a = AISinglePresenceHelper.create_data

          AUIControl.organize(@a,nil,0)
          @a.process_event(:present).should == [:wait_for_children]
        end
      end


    end

    describe 'synchronized with Redis-PubSub' do
      it 'should transform first child to presented if presented and rest to suspended' do
        connect true do |redis|

          parser = MINT::MappingParser.new
          m = parser.build_from_scxml File.dirname(__FILE__) +"/../lib/MINT-core/model/mim/aisinglepresence_present_to_child_present.xml"
          m.start

          check_result = Proc.new {
            test_state_flow redis,"Interactor.AIO.AIOUT.AIContainer.AISinglePresence" ,
                            ["defocused",["focused", "waiting"], "entered"] do
              @a.process_event(:focus)

              @a.process_event(:enter)
            end
            done

          }

          test_complex_state_flow_w_name redis,[["Interactor.AIO.AIOUT.AIContainer.AISinglePresence" ,"a",
                                                 ["initialized", "organized", ["presenting", "wait_for_children"] ,"children_finished","defocused"] ]],check_result do  |count|

            @a = AISinglePresenceHelper.create_data
            AUIControl.organize(@a,nil,0)

            @a.process_event(:present)



          end


        end
      end

    end

  end
end
