module StatemachineHelper
  def test_state_flow(redis, channel, expected_states)
     redis.subscribe(channel)

    redis.on(:message) { |c, message|
      p [:message, c, message]
      m = JSON.parse message
      r = expected_states.shift
      r = r.lines.to_a if r.is_a? String
      m["new_states"].should == r
      done if expected_states.length==0

    }
  end
end



