
require "spec_helper"

require "em-spec/rspec"

require "cui_helper"


describe 'Sync wth AIO' do
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

  it 'should sync highlight movements of CIO  to AUI' do
    connect true do |redis|

      # Sync AIO to defocused
      o3 = Observation.new(:element =>"Interactor.CIO", :states =>[:displayed],:result=>"cio",:process => :onchange)
      o4 = NegationObservation.new(:element =>"Interactor.AIO", :name =>"cio.name" ,:states =>[:defocused], :result => "aio",:process => :instant)
      a2 = EventAction.new(:event => :defocus, :target => "aio")
      m2 = MINT::SequentialMapping.new(:name=>"Sync AIO to defocused", :observations => [o3,o4],:actions =>[a2])
      m2.state_callback = Logging.method(:log)
      m2.start

      # Sync AIO to focused
      o3 = Observation.new(:element =>"Interactor.CIO", :states =>[:highlighted],:result=>"cio",:process => :onchange)
      o4 = NegationObservation.new(:element =>"Interactor.AIO", :name =>"cio.name" ,:states =>[:focused], :result => "aio",:process => :instant)
      a1 = EventAction.new(:event => :focus, :target => "aio")
      m1 = MINT::SequentialMapping.new(:name=>"Sync AIO to focused", :observations => [o3,o4],:actions =>[a1])

      m1.start

      check_result = Proc.new {
        MINT::AIO.first(:name=>"left").states.should ==[:focused]
        MINT::CIO.first(:name=>"left").states.should ==[:highlighted]
        MINT::AIO.first(:name=>"center").states.should ==[:defocused]

        done
      }


      test_complex_state_flow_w_name redis,[["Interactor.CIO","center" ,["initialized","displayed"]],["Interactor.AIO","center" ,["defocused"]]],check_result do  |count|
        center = CUIHelper.scenario2
        p "testcound:#{count}"
        center.process_event(:left).should ==[:displayed]
      end

#
    end
  end

  it 'should sync AUI focus movements to CUI' do
    connect true do |redis|
      # Sync CIO to displayed
      o1 = Observation.new(:element =>"Interactor.AIO", :states =>[:defocused],:result=>"aio",:process => :onchange)
      o2 = NegationObservation.new(:element =>"Interactor.CIO", :name =>"aio.name" ,:states =>[:displayed], :result => "cio",:process => :instant )
      a = EventAction.new(:event => :unhighlight, :target => "cio")
      m = MINT::SequentialMapping.new(:name=>"Sync CIO to displayed", :observations => [o1,o2],:actions =>[a])
      m.state_callback = Logging.method(:log)
      m.start

      # Sync CIO to highlighted
      o1 = Observation.new(:element =>"Interactor.AIO", :states =>[:focused],:result=>"aio",:process => :onchange)
      o2 = NegationObservation.new(:element =>"Interactor.CIO", :name =>"aio.name" ,:states =>[:highlighted], :result => "cio",:process => :instant )
      a = EventAction.new(:event => :highlight, :target => "cio")
      m = MINT::SequentialMapping.new(:name=>"Sync CIO to highlighted", :observations => [o1,o2],:actions =>[a])
      m.start


      check_result = Proc.new {
        MINT::AIO.first(:name=>"left").states.should ==[:focused]
        MINT::AIO.first(:name=>"center").states.should ==[:defocused]

        MINT::CIO.first(:name=>"center").states.should ==[:displayed]
        MINT::CIO.first(:name=>"left").states.should ==[:highlighted]

        done
      }

      test_complex_state_flow_w_name  redis,[["Interactor.AIO","center" ,["defocused"]],["Interactor.CIO","center" ,["displayed"]]],check_result do  |count|
        center = CUIHelper.scenario3
        a_center = MINT::AIO.first(:name => "center")
        a_center.process_event("next").should ==[:defocused]
      end




      #MINThighlightedst(:nameA>"dowleftates.should ==[:highlighted]
    end
  end
end