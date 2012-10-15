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
        test_state_flow redis,"Interactor.AIO.AIOUT.AIOUTContinuous.a" ,%w(initialized)  do

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
        test_state_flow redis,"Interactor.AIO.AIOUT.AIOUTContinuous.a" ,%w(initialized organized)   do

          MINT::AIOUTContinuous.new(:name=>"a").save
          @a = MINT::AIOUTContinuous.first

          @a.process_event(:organize).should ==[:organized]
          @a.states.should == [:organized]
          @a.new_states.should == [:organized]
        end
      end
    end

    it 'should transform to progressing and regressing state and consume value' do
      connect true  do |redis|
        test_state_flow redis,"Interactor.AIO.AIOUT.AIOUTContinuous.a" , [ "initialized", "organized",  ["presenting", "f", "p", "defocused", "waiting"],"focused",["moving", "progressing"],"regressing"] do
          Fiber.new {
            MINT::AIOUTContinuous.new(:name=>"a").save
            @a = MINT::AIOUTContinuous.first

            @a.process_event(:organize).should ==[:organized]

            @a.process_event(:present).should ==[:defocused, :waiting]
            @a.process_event(:focus).should ==[:focused, :waiting]

            channel_name = @a.create_attribute_channel_name('data')

            redis.publish(channel_name,MultiJson.encode({:data=>10,:name=>"a"}))
            redis.publish(channel_name,MultiJson.encode({:data=>5,:name=>"a"}))

          }.resume
        end
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

  end
end
