module MINT
  class Screen < Interactor
    property :root, String

    PUBLISH_ATTRIBUTES += [:root ]

    protected
    def initialize_statemachine
      if @statemachine.blank?
        @statemachine = Statemachine.build do
          trans :initialized, :calculate, :calculating
          trans :calculating, :done, :finished
          trans :finished, :calculate, :calculating
        end
      end
    end

  end

  class BrowserScreen < Interactor
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