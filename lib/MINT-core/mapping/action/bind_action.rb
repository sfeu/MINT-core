class BindAction < Action


  def initialize(params)
    @action = params
    @initiated_callback=nil
  end

  def initiated_callback(cb)
    @initiated_callback = cb
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
    RedisConnector.sub.subscribe(channelIn).callback do
      @initiated_callback.call(elementIn) if @initiated_callback
    end


    # This does not work, because claues are not stored in data model unless the streaming is stopped
    #e_class = MINT::Interactor.class_from_channel_name elementIn

    # element = e_class.first(:name=>nameIn)
    #d = element.attribute_get(@action[:attrIn])

    #RedisConnector.pub.publish @action[:elementOut], {:name=>@action[:nameOut], @action[:attrOut] => d}.to_json


    RedisConnector.sub.on(:message) do |c, message|
      if c.eql? channelIn
        p c

        found=JSON.parse message

        if nameIn.eql? found['name']

          if found.has_key? @action[:attrIn]
            result =  found[@action[:attrIn]]
            result = @action[:transform].call result if @action[:transform]
            RedisConnector.pub.publish channelOut, {:name=>@action[:nameOut], @action[:attrOut] => result}.to_json

          end
        end
      end
    end
  end

  def unbind
    RedisConnector.sub.unsubscribe(@action[:in])
  end
end