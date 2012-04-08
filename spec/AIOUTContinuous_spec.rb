require "spec_helper"

require "em-spec/rspec"


describe 'AUI' do
  include EventMachine::SpecHelper

  before :each do
    connection_options = { :adapter => "redis"}
    DataMapper.setup(:default, connection_options)

    DataMapper::Model.raise_on_save_failure = true
    redis = Redis.connect
    redis.flushdb


  end

  describe 'AIOUTContinuous' do
    it 'should initialize with initiated' do

      connect do |redis|
        require "MINT-core"

        DataMapper.finalize

        test_state_flow redis,"Interactor.AIO.AIOUT.AIOUTContinuous" ,%w(initialized)
        #MINT::Interactor.redis redis

        MINT::AIOUTContinuous.new(:name=>"a").save
        @a = MINT::AIOUTContinuous.first
        @a.states.should ==[:initialized]
        @a.new_states.should == [:initialized]
      end
    end

    it 'should transform to organizing state ' do

      connect do |redis|
        require "MINT-core"
        DataMapper.finalize

        test_state_flow redis,"Interactor.AIO.AIOUT.AIOUTContinuous" ,%w(initialized organized)

        MINT::AIOUTContinuous.new(:name=>"a").save
        @a = MINT::AIOUTContinuous.first

        @a.process_event(:organize).should ==[:organized]
        @a.states.should == [:organized]
        @a.new_states.should == [:organized]

      end
    end

    it 'should transform to progressing state ' do

      connect do |redis|
        require "MINT-core"
        DataMapper.finalize

        MINT::AIOUTContinuous.new(:name=>"a").save
        @a = MINT::AIOUTContinuous.first
        test_state_flow redis,"Interactor.AIO.AIOUT.AIOUTContinuous",
                        ["initialized","organized",["defocused","waiting","p", "c"],["focused"],
                         ["progressing", "moving", "c"]]
        @a.process_event(:organize).should ==[:organized]

        @a.process_event(:present).should ==[:defocused, :waiting]
        @a.process_event(:focus).should ==[:focused, :waiting]

        @a.process_event(:move).should ==[:focused, :progressing]


      end
    end

    it 'should transform to progressing state and consume value' do

      connect do |redis|
        require "MINT-core"
        DataMapper.finalize

        MINT::AIOUTContinuous.new(:name=>"a").save
        @a = MINT::AIOUTContinuous.first
        @a.process_event(:organize).should ==[:organized]

        @a.process_event(:present).should ==[:defocused, :waiting]
        @a.process_event(:focus).should ==[:focused, :waiting]

        @a.process_event(:move).should ==[:focused, :progressing]

        redis2 = EventMachine::Hiredis.connect
        redis2.publish("Interactor.AIO.AIOUT.AIOUTContinuous.1",10).callback { |c|
          @a.data.should==10
          redis2.publish("Interactor.AIO.AIOUT.AIOUTContinuous.1",20).callback { |c|
            @a.data.should==20
            redis2.publish("Interactor.AIO.AIOUT.AIOUTContinuous.1",10).callback { |c|
              @a.data.should==10
              @a.new_states.should==[:regressing]
              done
            }
          }
        }

      end
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