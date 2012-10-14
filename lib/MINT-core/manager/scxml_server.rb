
require 'rubygems'
require "bundler/setup"
require "MINT-core"
require "MINT-scxml"

class SCXMLServer
  attr_accessor :connections
  attr_accessor :manager

  class StatefulProtocol < EventMachine::Connection
    include EM::Protocols::LineText2
    attr_accessor :manager

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

          if(@state_store[key])
            activated_states =  @state_store[key]

            current_active_states = found["states"] + found["abstract_states"]

            deactivated_states = activated_states - current_active_states

            # send deactivate states

            deactivated_states.each {|state|
              p "deactivated: #{state}"
              send_inactive_state state
            }

            #save activated states
            @state_store[key] = current_active_states
          end
        end
      }.callback { p "subscribed to #{@interactor} name #{@name}"}

    end

    def send_active_state(name)
      send_data "1 #{name}"
    end

    def send_inactive_state(name)
      send_data "0 #{name}"
    end
  end

  def initialize(_interactor,_name)
    @interactor = _interactor
    @name = _name
  end

  def start(host="0.0.0.0",port=3001)
  EventMachine::start_server host, port, StatefulProtocol do |conn|
      conn.subscribe_redis(@interactor,@name)
      @connections << conn

      puts "connection..."

      # inform about all currently activated states
      # @state_store[@interactor]
    end
    puts "Started server on #{host}:#{port}"
  end

end

