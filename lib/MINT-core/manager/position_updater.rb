
require 'rubygems'
require "bundler/setup"
require "eventmachine"
require "MINT-scxml"

require 'redis'
require 'hiredis'

class PositionUpdater

    def initialize
    end

    def start()
      redis = EventMachine::Hiredis.connect

      redis.pubsub.psubscribe("in_channel:Interactor.CIO.coordinates.*") { |key, message|
        found=MultiJson.decode message
        cio = CIO.get "cui-gfx",found['name']
        #cio.x =found['x']
        #cio.y = found['y']
        cio.width=found['width']
        cio.height = found['height']
        cio.save
        CUIControl.update_cache(cio)
        puts found.inspect
      }.callback { p "subscribed to receive position updates"}

    end

end

