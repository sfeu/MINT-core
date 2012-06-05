require "spec_helper"
require "MINT-core"

class FakeSocketClient < EventMachine::Connection
  include EM::Protocols::LineText2

  attr_writer :onopen, :onclose, :onmessage, :onregistered
  attr_reader :data

  def initialize
    @state = :new
    @data = []

  end

 def set_expectations(mapping_name,expected_data)
   @mapping_name = mapping_name
       @expected_data = expected_data
   end
  def receive_line(data)
    @data << data
    if @state == :new
      @onopen.call if @onopen
      @state = :open
    end
    p "received #{data}"
    if data.eql? "READY"
      @state = :ready
      send_data("REGISTER|#{@mapping_name}\r\n")
    elsif data.eql? "REGISTERED|#{@mapping_name}"
      @state = :registered
      @onregistered.call if @onregistered

    else
      d = data.split("|")
      if d.length ==2
        if d[0].eql? @mapping_name
          JSON.parse(d[1]).should == @expected_data.shift

          EM::stop if @expected_data.length == 0
        end
      else
        p "Unknown command received:#{data}"
      end

    end
  end
  def unbind
    @onclose.call if @onclose
  end
end

describe "Mapping server" do
  include EventMachine::SpecHelper

  before :all do
    connection_options = { :adapter => "redis"}
    DataMapper.setup(:default, connection_options)

    connect do |redis|
      require "MINT-core"
      #require "support/redis_connector_monkey_patch"  # TODO dirty patch for a bug that i have not found :(
      DataMapper.finalize
      DataMapper::Model.raise_on_save_failure = true
    end
  end

  it "should open connection and accept register command" do
    em do
      server = MappingServer.new(:host => '0.0.0.0', :port => 12345)
      server.start

      # opens the socket client connection
      socket = EM.connect('0.0.0.0', 12345, FakeSocketClient)
      socket.set_expectations("Mouse Interactor Highlighting",[])
      # assigning the onopen client callback directly
      socket.onopen = lambda {

        server.connections.size.should == 1
        socket.data.last.chomp.should == "READY"
        EM.stop
      }

    end
  end

  it "should return information about mapping states after registration" do
      em do
        server = MappingServer.new(:host => '0.0.0.0', :port => 12345)
        server.start

        # opens the socket client connection
        socket = EM.connect('0.0.0.0', 12345, FakeSocketClient  )
        socket.set_expectations("Mouse Interactor Highlighting",[{"id"=>"33113", "mapping_state"=>"loaded"},{"id"=>"33113", "mapping_state"=>"started"},{"id"=>"111", "state"=>"activated"}])
        m = server.manager

        socket.onregistered= lambda {

        m.load("examples/mim_streaming_example.xml")
        mouse = MINT::Mouse.create(:name =>"mouse")  # previously activated observation should be false
        #mouse.process_event :connect # observation should be true
}
      end
    end
end