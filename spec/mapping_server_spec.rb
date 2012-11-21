require "spec_helper"

require "em-spec/rspec"

class FakeMappingServerClient < EventMachine::Connection
  include EM::Protocols::LineText2

  attr_writer :onopen, :onclose, :onmessage, :onregistered
  attr_reader :data

  def post_init
    @state = :new
    @data = []

  end

  def set_expectations(mapping_name,detail_level,expected_data)
    @mapping_name = mapping_name
    @expected_data = expected_data
    @detail_level = detail_level
  end
  def receive_line(rd)
    @data << rd
    if @state == :new
      @onopen.call if @onopen
      @state = :open
    end
    p "received #{rd}"
    if rd.eql? "READY"
      @state = :ready
      send_data("REGISTER%#{@mapping_name}%#{@detail_level}\r\n")
    elsif rd.eql? "REGISTERED%#{@mapping_name}%#{@detail_level}"
      @state = :registered
      @onregistered.call if @onregistered

    else
      d = rd.split("%")
      if d.length ==3
        if d[1].eql?  @mapping_name and (d[0].eql? "INFO" or d[0].eql? @detail_level)
          MultiJson.decode(d[2]).should == @expected_data.shift

          EM::stop if @expected_data.length == 0
        end
      else
        p "Unknown command received:#{rd}"
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
      class Logging
        def self.log(mapping,data)
          p "log: #{mapping} #{data}"
        end
      end
      DataMapper.finalize
      DataMapper::Model.raise_on_save_failure = true
    end
  end

  before(:each) do
      Redis.new(:db => 15).flushdb
  end

  it "should open connection and accept register command" do
    connect true do |redis|
      CUIControl.clearHighlighted

      server = MappingServer.new(:host => '0.0.0.0', :port => 12345)
      server.start

      # opens the socket client connection
      socket = EM.connect('0.0.0.0', 12345, FakeMappingServerClient)
      socket.set_expectations("Mouse Interactor Highlighting","INFO",[])
      # assigning the onopen client callback directly
      socket.onopen = lambda {

        server.connections.size.should == 1
        socket.data.last.chomp.should == "READY"
        EM.stop
      }

    end
  end

  it "should return all information about mapping states after registration with DETAIL" do
    connect true do |redis|
      CUIControl.clearHighlighted
      server = MappingServer.new(:host => '0.0.0.0', :port => 12345)
      server.start

      # opens the socket client connection
      socket = EM.connect('0.0.0.0', 12345, FakeMappingServerClient  )
      socket.set_expectations("Mouse Interactor Highlighting","DETAIL",[{"id"=>"33113", "mapping_state"=>"loaded"},
                                                                        {"id"=>"33113", "mapping_state"=>"started"},
                                                                        {"id"=>"111", "state"=>"activated"},
                                                                        {"id"=>"111", "element"=>"Interactor.IR.IRMode.Pointer.Mouse", "result"=>{}, "state"=>"false"},
                                                                        {"id"=>"111", "element"=>"Interactor.IR.IRMode.Pointer.Mouse", "result"=>{"p"=>{"classtype"=>"MINT::Mouse", "mint_model"=>"core", "name"=>"mouse", "states"=>["left_released", "stopped", "right_released"], "abstract_states"=>"Mouse|root|connected|leftbutton|pointer|rightbutton", "new_states"=>["connected", "leftbutton", "pointer", "rightbutton", "left_released", "stopped", "right_released"], "x"=>-1, "y"=>-1}}, "state"=>"true", "name"=>"mouse"},
                                                                        {"id"=>"2222", "state"=>"activated"},
                                                                        {"id"=>"2222", "state"=>"succeeded"},
                                                                        {"id"=>"33113", "mapping_state"=>"succeeded"},
                                                                        {"id"=>"33113", "mapping_state"=>"restarted"},
                                                                        {"id"=>"111", "state"=>"activated"}])
      m = server.manager

      socket.onregistered= lambda {
        m.load(File.dirname(__FILE__) +"/examples/mim_streaming_example.xml").started {
          mouse = MINT::Mouse.create(:name =>"mouse")  # previously activated observation should be false
          mouse.process_event :connect # observation should be true
          #mouse.process_event :move
          #mouse.process_event :stop

        }

      }
    end
  end
  it "should return all information about mapping states after registration with DETAIL" do
    connect true do |redis|
      CUIControl.clearHighlighted
      server = MappingServer.new(:host => '0.0.0.0', :port => 12345)
      server.start

      # opens the socket client connection
      socket = EM.connect('0.0.0.0', 12345, FakeMappingServerClient  )
      socket.set_expectations("Mouse Interactor Highlighting","INFO",[#{"id"=>"33113", "mapping_state"=>"loaded"},
                                                                       # {"id"=>"33113", "mapping_state"=>"started"},
                                                                        {"id"=>"33113", "mapping_state"=>"succeeded", "name"=>"mouse"}
                                                                        #{"id"=>"33113", "mapping_state"=>"restarted"}
                                                                        ])
      m = server.manager

      socket.onregistered= lambda {
        m.load(File.dirname(__FILE__) +"/examples/mim_streaming_example.xml").started {
          mouse = MINT::Mouse.create(:name =>"mouse")  # previously activated observation should be false
          mouse.process_event :connect # observation should be true
          #mouse.process_event :move
          #mouse.process_event :stop

        }

      }
    end
  end
end