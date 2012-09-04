
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
      parser = MINT::MappingParser.new
      m = parser.build_from_scxml File.dirname(__FILE__) +"/../lib/MINT-core/model/mim/cio_display_to_aio_defocus.xml"
      m.start

      # Sync AIO to focused
      parser = MINT::MappingParser.new
      m = parser.build_from_scxml File.dirname(__FILE__) +"/../lib/MINT-core/model/mim/cio_highlight_to_aio_focus.xml"
      m.start

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
      parser = MINT::MappingParser.new
      m = parser.build_from_scxml File.dirname(__FILE__) +"/../lib/MINT-core/model/mim/aio_defocus_to_cio_unhighlight.xml"
      m.start

      # Sync CIO to highlighted
      parser = MINT::MappingParser.new
      m = parser.build_from_scxml File.dirname(__FILE__) +"/../lib/MINT-core/model/mim/aio_focus_to_cio_highlight.xml"
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