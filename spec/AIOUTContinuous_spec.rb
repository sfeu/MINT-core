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

  describe 'AIOUTContinuous' do
    it 'should initialize with initiated' do

      connect true do |redis|


        test_state_flow redis,"Interactor.AIO.AIOUT.AIOUTContinuous" ,%w(initialized)  do
          MINT::AIOUTContinuous.new(:name=>"a").save
                  @a = MINT::AIOUTContinuous.first
                  @a.states.should ==[:initialized]
                  @a.new_states.should == [:initialized]

        end
        #MINT::Interactor.redis redis

        end
    end

    it 'should transform to organizing state ' do

      connect  true do |redis|

        test_state_flow redis,"Interactor.AIO.AIOUT.AIOUTContinuous" ,%w(initialized organized)   do

        MINT::AIOUTContinuous.new(:name=>"a").save
        @a = MINT::AIOUTContinuous.first

        @a.process_event(:organize).should ==[:organized]
        @a.states.should == [:organized]
        @a.new_states.should == [:organized]
                                                                                                     end
      end
    end

    it 'should transform to progressing state and consume value' do
      pending "test synchronization needs to be implemented"
      connect   do |redis|

        MINT::AIOUTContinuous.new(:name=>"a").save
        @a = MINT::AIOUTContinuous.first

        @a.process_event(:organize).should ==[:organized]

        @a.process_event(:present).should ==[:defocused, :waiting]
        @a.process_event(:focus).should ==[:focused, :waiting]
        test_msg_flow redis,"Interactor.AIO.AIOUT.AIOUTContinuous.data.a",@a,:data,[10,20,10], [{:data=>10,:name=>"a"},{:data=>20,:name=>"a"},{:data=>10,:name=>"a"}]

end
        #@a.process_event(:move).should ==[:focused, :progressing]

        #redis2 = EventMachine::Hiredis.connect
        #redis2.publish("Interactor.AIO.AIOUT.AIOUTContinuous.data.a",{:data=>10,:name=>"a"}.to_json).callback { |c|
        #  @a.data.should==10
        #  redis2.publish("Interactor.AIO.AIOUT.AIOUTContinuous.data.a",{:data=>20,:name=>"a"}.to_json).callback { |c|
        #    @a.data.should==20
        #    @a.new_states.should==[:progressing,:moving, :c]
        #    redis2.publish("Interactor.AIO.AIOUT.AIOUTContinuous.data.a",{:data=>10,:name=>"a"}.to_json).callback { |c|
        #      @a.data.should==10
        #      @a.new_states.should==[:regressing]
        #      done
        #    }
        #  }
        #}
        #



    end

    it "runs test code in an em block automatically" do
      em do
        start = Time.now
        EM.add_timer(0.5){
          (Time.now-start).should be_close( 0.5, 0.1 )
          done
        }
      end
    end
  end
end
