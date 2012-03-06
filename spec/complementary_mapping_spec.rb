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

      o1 = Observation.new(:element =>"Element.AIO.AIIN.AIINContinous",:name => "slider", :states =>[:progressing])

      o2 = Observation.new(:element =>"Element.AIO.AIOUT.AIOUTContinous",:name=>"volume", :states =>[:presenting])

      a1 = BindAction.new(:elementIn => "Element.AIO.AIIN.AIINContinous",:nameIn => "slider", :attrIn =>"data",:attrOut=>"data",
                          :transform =>:manipulate, :elementOut =>"Element.AIO.AIOUT.AIOUTContinous", :nameOut=>"volume" )
      m = ComplementaryMapping.new(:observations => [o1,o2],:actions =>[a1])
      m.initialized_callback(Proc.new {p "Hello World"})
      m.activated_callback(Proc.new {
        RedisConnector.pub.publish  'Element.AIO.AIIN.AIINContinous.slider:test', 20
        }
      )
      m.start
      volume = MINT2::AIOUTContinous.create(:name=>"volume")
      volume.process_event(:organize).should ==[:organized]
      volume.process_event(:present).should ==[:defocused, :waiting]

      slider = MINT2::AIINContinous.create(:name=>"slider")
      slider.process_event(:organize).should ==[:organized]
      slider.process_event(:present).should ==[:defocused]
      slider.process_event(:focus).should ==[:waiting]

      RedisConnector.pub.publish  'Element.AIO.AIIN.AIINContinous.slider:test', 10
      #RedisConnector.pub.publish  'Element.AIO.AIIN.AIINContinous.slider:test', 20



   #   done
    end
  end
end