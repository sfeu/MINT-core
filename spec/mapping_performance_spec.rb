require "spec_helper"
require "em-spec/rspec"
require 'perftools'

describe "MappingPerformance" do
  include EventMachine::SpecHelper

  before :all do
    connection_options = { :adapter => "redis"}
    DataMapper.setup(:default, connection_options)


    connect do |redis|
      require "MINT-core"
      class InteractorTest < MINT::Interactor
        def getSCXML
          "#{File.dirname(__FILE__)}/interactor_test.scxml"
        end
      end

      class PerformanceCounter < MINT::Interactor
        property :counter, Integer,  :default => 0
        property :amount, Integer,  :default => 10

        def inc_counter
          counter = attribute_get(:counter)
          attribute_set(:counter, counter + 1)

        end
        def getSCXML
          "#{File.dirname(__FILE__)}/performance_counter.scxml"
        end
      end

      require "support/redis_connector_monkey_patch"  # TODO dirty patch for a bug that i have not found :(
      DataMapper.finalize
      DataMapper::Model.raise_on_save_failure = true
    end
  end


  it "should run as quickly as possible for one mapping" do
      connect true do |redis|
        parser = MINT::MappingParser.new
        m = parser.build_from_scxml File.dirname(__FILE__) +"/examples/performance_mapping.xml"
        m.start

        check_result = Proc.new {


          done
        }

        test_complex_state_flow_w_name  redis,[["Interactor.PerformanceCounter","counter" ,["initialized","finished"]]],check_result do  |count|
          counter = PerformanceCounter.create(:name=>"counter",:amount =>1)
          trigger = InteractorTest.create(:name=>"test")
          trigger.process_event :organize
        end


      end
  end

  it "should run as quickly as possible for two mappings" do
    connect true do |redis|
      parser = MINT::MappingParser.new
      m = parser.build_from_scxml File.dirname(__FILE__) +"/examples/performance_mapping.xml"
      m.start

      m = parser.build_from_scxml File.dirname(__FILE__) +"/examples/performance_mapping.xml"
      m.start

      check_result = Proc.new {
        done
      }

      test_complex_state_flow_w_name  redis,[["Interactor.PerformanceCounter","counter" ,["initialized","initialized","finished"]]],check_result do  |count|
        counter = PerformanceCounter.create(:name=>"counter",:amount =>2)
        trigger = InteractorTest.create(:name=>"test")
        trigger.process_event :organize
      end


    end
  end

  it "should run as quickly as possible for 1000 mappings" do
    PerfTools::CpuProfiler.start("/tmp/add_numbers_profile") do
    connect(true,30) do |redis|
      parser = MINT::MappingParser.new

      obs_array =[]

      for i in 1..500 do
        m = parser.build_from_scxml File.dirname(__FILE__) +"/examples/performance_mapping.xml"
        m.start
        obs_array << "initialized"
      end

      obs_array << "finished"

      p obs_array

      check_result = Proc.new {
        done
      }

      test_complex_state_flow_w_name  redis,[["Interactor.PerformanceCounter","counter" ,obs_array]],check_result do  |count|
        counter = PerformanceCounter.create(:name=>"counter",:amount =>500)
        trigger = InteractorTest.create(:name=>"test")
        trigger.process_event :organize
      end

    end

    end
  end
end