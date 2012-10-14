
require 'rubygems'
require "bundler/setup"
require "MINT-core"
require "MINT-scxml"

class MappingServer
  attr_accessor :connections
  attr_accessor :manager

  class StatefulProtocol < EventMachine::Connection
    include EM::Protocols::LineText2
    attr_accessor :manager

    def initialize
      @mapping_store = {}

      # saves if a registered mapping is detail
      @registered_as_detail = {}
      super()
    end

    def forward_callback(mapping,data)
      p "in forward #{mapping} #{data}"

      if (data[:result])
        d = data[:result]
        if not d.nil? and not d.empty? and not @mapping_store[mapping]
          #a= d.first
          #b = a[1]['name']
          if d.first[1].is_a? Hash
            @mapping_store[mapping] =  {:name => d.first[1]['name']}

          else

            @mapping_store[mapping] =  {:name => d.first[1].map{|x| x['name']}}
          end
        end
      end
      json_data = (@mapping_store[mapping]!=nil)?MultiJson.encode(data.merge(@mapping_store[mapping])) :  MultiJson.encode(data)
      if data[:mapping_state] and data[:mapping_state] == :succeeded
        send_data("INFO%"+mapping+"%"+json_data+"\r\n")
        p "sent: INFO%"+mapping+"%"+json_data
        @mapping_store[mapping]=nil
      elsif  @registered_as_detail[mapping]
        send_data("DETAIL%"+mapping+"%"+json_data+"\r\n")
        p "sent: DETAIL%"+mapping+"%"+json_data
        @mapping_store[mapping]=nil
      end

    end

    def receive_line(data)
      begin
        p "server received:#{data}"
        d = data.split('%')

        case d[0]
          when "REGISTER"
            @manager.register_callback(d[1], method(:forward_callback))
            @registered_as_detail[d[1]] = d[2].eql?('DETAIL')?true:false
            send_data("REGISTERED%#{d[1]}%#{d[2]}\r\n")
          when "LIST"
            mappings = @manager.get_mappings
            mappings.each {|m| send_data("MAPPING%#{m}\r\n")}
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


