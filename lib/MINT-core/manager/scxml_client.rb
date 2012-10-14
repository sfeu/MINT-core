
require 'rubygems'
require "bundler/setup"
require "eventmachine"
require "MINT-scxml"

require 'redis'
require 'hiredis'

class SCXMLClient
  attr_accessor :connections

  def self.state_store
   @@state_store ||= {}
  end


  class StatefulProtocol < EventMachine::Connection
    include EM::Protocols::LineText2

    def initialize
      super()
    end

    def subscribe_redis(interactor,name)
      @interactor = interactor
      @name = name

      redis = EventMachine::Hiredis.connect

      redis.pubsub.psubscribe(@interactor) { |key, message|

        found=MultiJson.decode message
        if @name.nil? or @name.eql? found["name"]
          if found.has_key? "new_states"
            # send new state
            found["new_states"].each { |state|
              p "activated: #{state}"
              send_active_state state }
          end

          current_active_states = found["states"] + found["abstract_states"].split("|")
          if(SCXMLClient.state_store.has_key? key)
            activated_states =  SCXMLClient.state_store[key]



            deactivated_states = activated_states - current_active_states

            # send deactivate states

            deactivated_states.each {|state|
              p "deactivated: #{state}"
              send_inactive_state state
            }

            #save activated states

          end
          SCXMLClient.state_store[key] = current_active_states
        end
      }.callback { p "subscribed to #{@interactor} name #{@name}"}

    end

    def send_active_state(name)
      send_data "1 #{name}\r\n"
    end

    def send_inactive_state(name)
      send_data "0 #{name}\r\n"
    end
  end

  def initialize(_interactor,_name)
    @interactor = _interactor
    @name = _name

  end

  def start(host="0.0.0.0",port=3003)

    socket = EM.connect(host, port, StatefulProtocol) do |conn|
      conn.subscribe_redis(@interactor,@name)

      puts "SCXML client connection..."

      # inform about all currently activated states
      # @state_store[@interactor]
    end
  end

end

