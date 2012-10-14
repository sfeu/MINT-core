class BindAction < Action


  def initialize(params)
    super()
    @action = params
    @cb_observation_has_subscribed=nil
    @is_bound = false
  end

  def initiated_callback(cb)
    @cb_observation_has_subscribed = cb
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
    "#{attrIn}:#{elementIn}.#{nameIn}"
  end

  def channelOut
    "#{attrOut}:#{elementOut}.#{nameOut}"
  end


  def start(observation_results)            # TODO handle observation_variables
    @result = false
    if @is_bound
      @cb_observation_has_subscribed.call(elementIn) if @cb_observation_has_subscribed
      return self
    end

    redis = RedisConnector.redis
    redis.pubsub.subscribe(channelIn) { |message|


      found=MultiJson.decode message

      if nameIn.eql? found['name']

        if found.has_key? @action[:attrIn]
          result =  found[@action[:attrIn]]
          result = @action[:transform].call result if @action[:transform]
          redis.publish channelOut, MultiJson.encode({:name=>@action[:nameOut], @action[:attrOut] => result})

        end

      end
    }.callback do
      @is_bound = true
      @cb_observation_has_subscribed.call(elementIn) if @cb_observation_has_subscribed
    end
    @result = true
    self
  end

  def unbind
    RedisConnector.sub.unsubscribe(@action[:in])
  end
end