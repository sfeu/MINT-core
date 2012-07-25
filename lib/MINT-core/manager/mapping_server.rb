
require 'rubygems'
require "bundler/setup"
require "MINT-core"
require "MINT-scxml"
require 'json'

class MappingServer
  attr_accessor :connections
  attr_accessor :manager

  class StatefulProtocol < EventMachine::Connection
    include EM::Protocols::LineText2
    attr_accessor :manager

    def initialize
      @mapping_store = {}
      super()
    end

    def forward_callback(mapping,data)
      p "in forward #{mapping} #{data}"

      if (data[:result])
        d = data[:result]
        if not @mapping_store[mapping] and d.first and d.first[1]['name']
          @mapping_store[mapping] =  {:name => d.first[1]['name']}
        end
      end
      if data[:mapping_state]
        if data[:mapping_state].eql? :succeeded
          send_data("STATUS|"+mapping+"|"+@mapping_store[mapping].to_json+"\r\n")
          p "sent: STATUS|"+mapping+"|"+@mapping_store[mapping].to_json
        end
        @mapping_store[mapping]=nil
      end


    end

    def receive_line(data)
      begin
        p "server received:#{data}"
        d = data.split('|')

        case d[0]
          when "REGISTER"
            @manager.register_callback(d[1], method(:forward_callback))
            send_data("REGISTERED|#{d[1]}\r\n")
          when "LIST"
            mappings = @manager.get_mappings
            mappings.each {|m| send_data("MAPPING|#{m}\r\n")}
          else
            p "ERROR\r\nReceived Unknown data:#{data}\r\n "
        end
      end
    rescue Statemachine::TransitionMissingException => bang
      puts "ERROR\n#{bang}"
    end
  end

  def initialize(hsh = {:host=>"0.0.0.0",:port=>8000})
    @host = hsh[:host]
    @port = hsh[:port]
    @connections =[]
  end

  def start(manager = nil)

    if (manager)
      @manager = manager
    else
      @manager = MappingManager.new
    end
    EventMachine::start_server @host, @port, StatefulProtocol do |conn|
      @connections << conn
      conn.send_data("READY\r\n")
      conn.manager=@manager
      puts "connection..."
    end
    puts "Started server on #{@host}:#{@port}"
  end

end


