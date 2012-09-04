require "spec_helper"
require "em-spec/rspec"

describe 'MappingManager' do
  include EventMachine::SpecHelper

  before :all do
    connection_options = { :adapter => "redis"}
    DataMapper.setup(:default, connection_options)


    connect do |redis|
      require "MINT-core"
      require "support/redis_connector_monkey_patch"  # TODO dirty patch for a bug that i have not found :(
      DataMapper.finalize
      DataMapper::Model.raise_on_save_failure = true
    end
  end


  it 'should register and call callback for loaded' do
    connect true do |redis|
      m = MappingManager.new
      @data = []

      def my_callback(mapping_name,data)
        if mapping_name.eql? "Reset Click"
          @data << data
        end
      end

      m.register_callback("Reset Click", method(:my_callback))
      m.load(File.dirname(__FILE__) +"/examples/mim_streaming_example.xml")
      d = @data.shift
      d[:mapping_state].should == :loaded
      @data.length.should == 0
      done
    end

  end

  it 'should register and call callback for loaded and started' do
    connect true do |redis|

      m = MappingManager.new
      @data = []

      def my_callback(mapping_name,data)
        if mapping_name.eql? "Mouse Interactor Highlighting"
          @data << data
        end
      end

      m.register_callback("Mouse Interactor Highlighting", method(:my_callback))
      m.load(File.dirname(__FILE__) +"/examples/mim_streaming_example.xml")

      d = @data.shift
      d[:mapping_state].should == :loaded

      d = @data.shift
      d[:mapping_state].should == :started
      #There are other callbacks @data.length.should == 0
      done
    end

  end

  it 'should activate observations after mapping has been started' do
   # pending "Needs to be fixed by Jessica"
    connect true,120 do |redis|


      m = MappingManager.new
      @counter = 0

      # we need to move all checks into the callback, since after the mapping is started, we are async...
      def my_callback(mapping_name,data)
        if mapping_name.eql? "Mouse Interactor Highlighting"
          p @counter
          case @counter
            when 0
              data[:mapping_state].should == :loaded
            when 1
              data[:mapping_state].should == :started
            when 2
              data[:id].should == "111"
              data[:state].should == :activated

              @mouse = MINT::Mouse.create(:name =>"mouse")  # previously activated observation should be false

            when 3
              data[:id].should == "111"
              data[:state].should == :false
              @mouse.process_event :connect # observation should be true
            when 4
              data[:id].should == "111"
              data[:state].should == :true
            when 5
              data[:id].should == "2222"
              data[:state].should == :activated
            when 6
              data[:id].should == "2222"
              data[:state].should == :succeeded
            when 7
              data[:id].should == "33113"
              data[:mapping_state].should == :succeeded
            when 8
              data[:id].should == "33113"
              data[:mapping_state].should == :restarted #cool would be :restarted for this case
            when 9
              data[:id].should == "111"
              data[:state].should == :activated
              p "terminate"
              done
          end
          @counter +=1
        end
      end

      m.register_callback("Mouse Interactor Highlighting",method(:my_callback))
      m.load(File.dirname(__FILE__) +"/examples/mim_streaming_example.xml")


    end
  end
end
