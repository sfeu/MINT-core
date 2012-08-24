module MINT

  class BrowserScreen < Screen
    def getSCXML
      "#{File.dirname(__FILE__)}/browserscreen.scxml"
    end

    def subscribe_for_refresh
      return if @subscribed

      redis = RedisConnector.redis

      fiber = Fiber.current

      redis.pubsub.psubscribe('in_channel:Interactor.BrowserScreen.reload*') { |key,message|
        if message
          process_event :reload
        end

      }.callback {  @subscribed = true; fiber.resume}
      Fiber.yield


    end

  end
end