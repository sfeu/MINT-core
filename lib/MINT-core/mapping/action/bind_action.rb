class BindAction < Action


  def initialize(params)
    @action = params
    @cb_observation_has_subscribed=nil
  end

  def initiated_callback(cb)
    @cb_observation_has_subscribed = cb
  end

  def id
    @action[:id]
  end

  def elementIn
    @action[:elementIn]
  end

  def elementOut
    @action[:elementOut]
  end

  def identifier
    elementIn
  end

  def nameIn
    @action[:nameIn]
  end

  def nameOut
    @action[:nameOut]
  end

  def attrIn
    @action[:attrIn]
  end

  def attrOut
    @action[:attrOut]
  end

  def channelIn
    "#{elementIn}.#{attrIn}.#{nameIn}"
  end

  def channelOut
    "#{elementOut}.#{attrOut}.#{nameOut}"
  end


  def start(observation_results)            # TODO handle observation_variables
    redis = RedisConnector.redis
    redis.pubsub.subscribe(channelIn) { |message|


      found=JSON.parse message

      if nameIn.eql? found['name']

        if found.has_key? @action[:attrIn]
          result =  found[@action[:attrIn]]
          result = @action[:transform].call result if @action[:transform]
          RedisConnector.pub.publish channelOut, {:name=>@action[:nameOut], @action[:attrOut] => result}.to_json

        end

      end
    }.callback do
      @cb_observation_has_subscribed.call(elementIn) if @cb_observation_has_subscribed
    end
    self
  end

  def unbind
    RedisConnector.sub.unsubscribe(@action[:in])
  end
end