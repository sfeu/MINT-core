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

  it "should be work correctly" do
    em do

      # capture the result an the very end: the message from the volume interactor to move the progress bar
      # presentation to 20 - additionally checks for correct states for bothe interactors

      r = RedisConnector.sub
      r.subscribe 'ss:channels'
      r.on(:message) { |channel, msg|

        if channel.eql? 'ss:channels'
          r = JSON.parse msg

          r["params"]["data"].should== 20

          volume = MINT::AIOUTContinuous.first(:name=>"volume")
          volume.states.should==[:defocused, :progressing]

          slider = MINT::AIINContinuous.first(:name=>"slider")
          slider.states.should==[:progressing]

          done
        end
      }

      # setup a waiting volume and slider interactor
      volume = MINT::AIOUTContinuous.create(:name=>"volume")
      volume.process_event(:organize).should ==[:organized]
      volume.process_event(:present).should ==[:defocused, :waiting]

      slider = MINT::AIINContinuous.create(:name=>"slider")
      slider.process_event(:organize).should ==[:organized]
      slider.process_event(:present).should ==[:defocused]
      slider.process_event(:focus).should ==[:waiting]


      o1 = Observation.new(:element =>"Interactor.AIO.AIIN.AIINContinuous",:name => "slider", :states =>[:progressing])
      o2 = Observation.new(:element =>"Interactor.AIO.AIOUT.AIOUTContinuous",:name=>"volume", :states =>[:presenting])
      a1 = BindAction.new(:elementIn => "Interactor.AIO.AIIN.AIINContinuous",:nameIn => "slider", :attrIn =>"data",:attrOut=>"data",
                          #:transform =>:manipulate,
                          :elementOut =>"Interactor.AIO.AIOUT.AIOUTContinuous", :nameOut=>"volume" )
      m = ComplementaryMapping.new(:observations => [o1,o2],:actions =>[a1])
      m.initialized_callback(Proc.new {p "Hello World"})
      m.activated_callback(Proc.new {
        # after mapping has been initialized simulate a user "test" moving the slider to 20
        RedisConnector.pub.publish  'Interactor.AIO.AIIN.AIINContinuous.slider:test', 20
      }
      )
      m.start
    end
  end
end