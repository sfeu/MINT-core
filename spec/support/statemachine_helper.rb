module StatemachineHelper
  def test_state_flow(redis, channel, expected_states, &blk)
    redis.subscribe(channel).callback {blk.call}

    redis.on(:message) { |c, message|
      p [:message, c, message]
      m = JSON.parse message
      r = expected_states.shift
      r = r.lines.to_a if r.is_a? String
      m["new_states"].should == r

      done if expected_states.length==0
    }
    EM.add_timer(3) {
      raise "failed to wait for state change to >>#{expected_states.first}<<, which not occurred during the last 3 seconds"
      done # EM.stop

    }
  end

  def test_msg_flow (redis,channel,interactor,attribute,value, publish_data)

    #redis.subscribe(interactor.create_channel_name).callback {blk.call}

     #   redis.on(:message) { |c, message|

    end_reached = publish_data.length
    publish_data.each_with_index do |data,i|
      redis.publish(channel,data.to_json).callback { |c|
        #interactor.method(attribute).call.should == value[i]
        done if end_reached == i
      }
    end

  end
end



