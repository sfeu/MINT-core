require "spec_helper"

require "MINT-core"


class FakeSocketClient < EventMachine::Connection
  include EM::Protocols::LineText2

  attr_reader :data

  def initialize

  end

  def set_data(data)
    @data = data

  end
  def post_init
    send_data "HeadMove/10,1/10,0/10,1/-1,6\r\n"
    # send_data "HeadMove/10,1/10,0/10,1/-1,6\r\n"
  end

end

describe "Complementary mapping" do
  include EventMachine::SpecHelper

  before :all do
    connection_options = { :adapter => "redis"}
    DataMapper.setup(:default, connection_options)

    connect do |redis|
      require "MINT-core"
      #require "support/redis_connector_monkey_patch"  # TODO dirty patch for a bug that i have not found :(
      DataMapper.finalize
      DataMapper::Model.raise_on_save_failure = true
    end
  end
  describe "with BindAction" do
    it "between AIINContinuous and AIOUTContinuouss should work correctly" do
      connect true do |redis|

        # capture the result an the very end: the message from the volume interactor to move the progress bar
        # presentation to 20 - additionally checks for correct states for bothe interactors

        redis.pubsub.subscribe("ss:channels") { |message|

          if channel.eql? 'ss:channels'
            r = MultiJson.decode msg

            r["params"]["data"].should== 20

            volume = MINT::AIOUTContinuous.first(:name=>"volume")
            volume.states.should==[:defocused, :progressing]

            slider = MINT::AIINContinuous.first(:name=>"slider")
            slider.states.should==[:progressing]

            done
          end
        }

        o1 = Observation.new(:element =>"Interactor.AIO.AIIN.AIINContinuous",:name => "slider", :states =>[:progressing], :process=>"onchange")
        o2 = Observation.new(:element =>"Interactor.AIO.AIOUT.AIOUTContinuous",:name=>"volume", :states =>[:presenting], :process=>"onchange")
        a1 = BindAction.new(:elementIn => "Interactor.AIO.AIIN.AIINContinuous",:nameIn => "slider", :attrIn =>"data",:attrOut=>"data",
                            #:transform =>:manipulate,
                            :elementOut =>"Interactor.AIO.AIOUT.AIOUTContinuous", :nameOut=>"volume" )
        m = MINT::ComplementaryMapping.new(:name => "Mapping_spec", :observations => [o1,o2],:actions =>[a1])
        m.start


        check_result = Proc.new {

        }

        test_state_flow redis,"Interactor.AIO.AIIN.AIINContinuous.slider",["initialized","organized",["presenting", "defocused"],["focused", "waiting"],["moving","progressing"]] do
          Fiber.new {
            # setup a waiting volume and slider interactor
            volume = MINT::AIOUTContinuous.create(:name=>"volume")
            volume.process_event(:organize).should ==[:organized]
            volume.process_event(:present).should ==[:defocused, :waiting]

            slider = MINT::AIINContinuous.create(:name=>"slider")
            slider.process_event(:organize).should ==[:organized]
            slider.process_event(:present).should ==[:defocused]
            slider.process_event(:focus).should ==[:waiting]
            redis.publish  'in_channel:Interactor.AIO.AIIN.AIINContinuous.slider:test', 20

          }.resume

        end


      end
    end
    it "between Head angle and AIOUTContinuous with transformation should work correctly" do
      pending "test not finished"
      connect true do |redis|

        # capture the result an the very end: the message from the volume interactor to move the progress bar
        # presentation to 20 - additionally checks for correct states for bothe interactors

        redis.pubsub.subscribe("out_channel:Interactor.AIO.AIOUT.AIOUTContinuous.horizontal_level:testuser") { |message|

          message.should== "40"

          volume = MINT::AIOUTContinuous.first(:name=>"horizontal_level")
          volume.states.should==[:defocused, :progressing]


          done

        }

        #<observation id="22" interactor="Interactor.Head" name="head" states="tilting_detection" process="onchange"/>
        #    <observation id="23" interactor="Interactor.AIO.AIOUT.AIOUTContinuous" name="horizontal_level" states="presenting" process="instant"/>
        #  </observations>
        #  <actions>
        #    <bind id="33" interactor_in="Interactor.Head" name_in="head" attr_in="head_angle" interactor_out="Interactor.AIO.AIOUT.AIOUTContinuous" name_out="horizontal_level" attr_out="data" transformation="head_angle_transformation" class="MusicSheet"/>
        #  </actions>

        def head_angle_transformation(angle)
          r = (angle / Math::PI * 100 * 80 / 100).abs.to_i
          p "result #{r}"
          return r
        end

        o1 = Observation.new(:element =>"Interactor.IR.IRMode.Body.Head",:name => "head", :states =>[:tilting_detection], :process=>"onchange")
        o2 = Observation.new(:element =>"Interactor.AIO.AIOUT.AIOUTContinuous",:name=>"horizontal_level", :states =>[:presenting], :process=>"onchange")
        a1 = BindAction.new(:elementIn => "Interactor.IR.IRMode.Body.Head",:nameIn => "head", :attrIn =>"head_angle",:attrOut=>"data",
                            :transform => self.method(:head_angle_transformation),
                            :elementOut =>"Interactor.AIO.AIOUT.AIOUTContinuous", :nameOut=>"horizontal_level" )
        m = MINT::ComplementaryMapping.new(:name => "Mapping_spec", :observations => [o1,o2],:actions =>[a1])
        m.start

        check_result = Proc.new {

        }

        test_state_flow_w_name redis,"Interactor.IR.IRMode.Body.Head","head",["disconnected",["tilting_detection", "face_detected", "connected", "centered"],"tilting_left"],check_result do
          Fiber.new{
            # setup a waiting volume and slider interactor
            volume = MINT::AIOUTContinuous.create(:name=>"horizontal_level")
            volume.process_event(:organize).should ==[:organized]
            volume.process_event(:present).should ==[:defocused, :waiting]

            MINT::Head.create(:name=>"head")
            socket = EM.connect('0.0.0.0', 4242, FakeSocketClient)

          }.resume

        end
      end
    end

  end
end