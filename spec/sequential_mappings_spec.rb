require "spec_helper"

require "em-spec/rspec"

describe 'In a sequential mapping' do
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

  it 'observations and events should handle list of interactors' do
    def my_callback(mapping_name,data)
      if mapping_name.eql? "Reset Click"
        @data << data
      end
    end


    connect true do |redis|
      m = MappingManager.new

      def my_callback(mapping_name,data)
        p data

      end

      m.register_callback("BrowserScreen reload to CIO refresh", method(:my_callback))
      m.load("#{File.dirname(__FILE__)}/examples/mim_streaming_example.xml")


      check_result = Proc.new {
        MINT::CIO.first(:name=>"c1").states.should ==[:displayed]
        MINT::CIO.first(:name=>"c2").states.should ==[:displayed]
        MINT::CIO.first(:name=>"c3").states.should ==[:hidden]

        done
      }

      test_complex_state_flow_w_name redis,[["Interactor.CIO","c1" ,["refreshing",["displaying", "init_js"],"displayed"]],["Interactor.CIO","c2" ,["refreshing",["displaying", "init_js"],"displayed"]],["Interactor.CIO","c3" ,["refreshing_while_hidden","hidden"]]],check_result do  |count|
        Fiber.new{
          b = MINT::BrowserScreen.create(:name=>'screen')
          MINT::AIO.create(:name =>"c1", :states=>[:presenting])
                    MINT::AIO.create(:name =>"c2", :states=>[:presenting])
                    MINT::AIO.create(:name =>"c3", :states=>[:suspended])

          MINT::CIO.create(:name =>"c1", :states=>[:displayed])
          MINT::CIO.create(:name =>"c2", :states=>[:displayed])
          MINT::CIO.create(:name =>"c3", :states=>[:hidden])

          b.process_event :reload
        }.resume
      end
    end
  end
end