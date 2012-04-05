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

  describe 'AIOUTContinous' do
    it 'should initialize with initiated' do

      connect do |redis|
        require "MINT-core"

        DataMapper.finalize

        test_state_flow redis,"Element.AIO.AIOUT.AIOUTContinous" ,%w(initialized)
        #MINT::Element.redis redis

        MINT2::AIOUTContinous.new(:name=>"a").save
        @a = MINT2::AIOUTContinous.first
        @a.states.should ==[:initialized]
        @a.new_states.should == [:initialized]
      end
    end

    it 'should transform to organizing state ' do

      connect do |redis|
        require "MINT-core"
        DataMapper.finalize

        test_state_flow redis,"Element.AIO.AIOUT.AIOUTContinous" ,%w(initialized organized)

        MINT2::AIOUTContinous.new(:name=>"a").save
        @a = MINT2::AIOUTContinous.first

        @a.process_event(:organize).should ==[:organized]
        @a.states.should == [:organized]
        @a.new_states.should == [:organized]

      end
    end

    it 'should transform to progressing state ' do

      connect do |redis|
        require "MINT-core"
        DataMapper.finalize

        MINT2::AIOUTContinous.new(:name=>"a").save
        @a = MINT2::AIOUTContinous.first
        test_state_flow redis,"Element.AIO.AIOUT.AIOUTContinous",
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

        MINT2::AIOUTContinous.new(:name=>"a").save
        @a = MINT2::AIOUTContinous.first
        @a.process_event(:organize).should ==[:organized]

        @a.process_event(:present).should ==[:defocused, :waiting]
        @a.process_event(:focus).should ==[:focused, :waiting]

        @a.process_event(:move).should ==[:focused, :progressing]

        redis2 = EventMachine::Hiredis.connect
        redis2.publish("Element.AIO.AIOUT.AIOUTContinous.1",10).callback { |c|
          @a.data.should==10
          redis2.publish("Element.AIO.AIOUT.AIOUTContinous.1",20).callback { |c|
            @a.data.should==20
            redis2.publish("Element.AIO.AIOUT.AIOUTContinous.1",10).callback { |c|
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
