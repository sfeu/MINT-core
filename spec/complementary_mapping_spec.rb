require "spec_helper"

require "MINT-core"


describe "Complementary mapping" do
  include EventMachine::SpecHelper
  before :each do
    connection_options = { :adapter => "redis"}
    DataMapper.setup(:default, connection_options)

    DataMapper::Model.raise_on_save_failure = true
    @redis = Redis.connect
    @redis.flushdb
    DataMapper.finalize

  end

  it "should be initialized correctly" do
    em do

      RedisConnector.sub.subscribe 'ss:channels'

      RedisConnector.sub.on(:message) { |channel, msg|

        if channel.eql? 'ss:channels'
          r = JSON.parse msg
          if r["params"]["data"].to_i == 20
            done
          else

            p "received from channels #{r.inspect}"
          end
        end
      }


      o1 = Observation.new(:element =>"Interactor.AIO.AIIN.AIINContinuous",:name => "slider", :states =>[:progressing])

      o2 = Observation.new(:element =>"Interactor.AIO.AIOUT.AIOUTContinuous",:name=>"volume", :states =>[:presenting])

      a1 = BindAction.new(:elementIn => "Interactor.AIO.AIIN.AIINContinuous",:nameIn => "slider", :attrIn =>"data",:attrOut=>"data",
                          #:transform =>:manipulate,
                          :elementOut =>"Interactor.AIO.AIOUT.AIOUTContinuous", :nameOut=>"volume" )
      m = ComplementaryMapping.new(:observations => [o1,o2],:actions =>[a1])
      # m.initialized_callback(Proc.new {p "Hello World"})
      m.activated_callback(Proc.new {
        RedisConnector.pub.publish  'Interactor.AIO.AIIN.AIINContinuous.slider:test', 20
      }
      )
      m.start
      volume = MINT::AIOUTContinuous.create(:name=>"volume")
      volume.process_event(:organize).should ==[:organized]
      volume.process_event(:present).should ==[:defocused, :waiting]

      slider = MINT::AIINContinuous.create(:name=>"slider")
      slider.process_event(:organize).should ==[:organized]
      slider.process_event(:present).should ==[:defocused]
      slider.process_event(:focus).should ==[:waiting]

      RedisConnector.pub.publish  'Interactor.AIO.AIIN.AIINContinuous.slider:test', 10
    end
  end
end