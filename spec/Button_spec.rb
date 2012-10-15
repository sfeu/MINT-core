require "spec_helper"

require "em-spec/rspec"

require "cui_helper"


describe 'CUI' do
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

  describe 'Button' do

    it 'should initialize' do
      connect true do |redis|
        require "MINT-core"

        DataMapper.finalize

        test_state_flow redis,"Interactor.CIO.Button.test" ,%w(initialized) do

          MINT::Button.create(:name => "test")

        end
      end
    end
    it 'should highlight based on AICommand update to focus' do
      connect true,120 do |redis|

        parser = MINT::MappingParser.new
        m = parser.build_from_scxml File.dirname(__FILE__)+"/../lib/MINT-core/model/mim/aio_present_to_cio_display.xml"
        m.start

        # Sync AIO to focused
        parser = MINT::MappingParser.new
        m = parser.build_from_scxml File.dirname(__FILE__)+"/../lib/MINT-core/model/mim/aio_focus_to_cio_highlight.xml"
        m.start

        test_state_flow redis,"Interactor.CIO.Button.reset" ,[["p", "b", "displaying", "d", "released", "init_js"] ,"displayed","highlighted"] do
          MINT::Button.create(:name=>"reset",:height =>60, :width => 200, :x=>380, :y => 150, :states=>[:positioned], :highlightable =>true)
          c = MINT::AICommand.create(:name=>"reset", :states=>[:organized])
          c.process_event :present
          c.process_event :focus
        end
      end
    end

    it 'should sync to pressed and released based on AICommand' do
      connect true,120 do |redis|

        parser = MINT::MappingParser.new
        m = parser.build_from_scxml File.dirname(__FILE__)+"/../lib/MINT-core/model/mim/aio_present_to_cio_display.xml"
        m.start

        parser = MINT::MappingParser.new
        m = parser.build_from_scxml File.dirname(__FILE__)+"/../lib/MINT-core/model/mim/aio_focus_to_cio_highlight.xml"
        m.start

        parser = MINT::MappingParser.new
        m = parser.build_from_scxml  File.dirname(__FILE__)+"/../lib/MINT-core/model/mim/aicommand_activate_to_button_press.xml"
        m.start

        parser = MINT::MappingParser.new
        m = parser.build_from_scxml  File.dirname(__FILE__)+"/../lib/MINT-core/model/mim/aicommand_deactivate_to_button_release.xml"
        m.start


        test_state_flow redis,"Interactor.CIO.Button.reset" ,[["p", "b", "displaying", "d", "released", "init_js"],"displayed","highlighted","pressed","released"] do
          MINT::Button.create(:name=>"reset",:height =>60, :width => 200, :x=>380, :y => 150, :states=>[:positioned], :highlightable =>true)
          c = MINT::AICommand.create(:name=>"reset", :states=>[:organized])
          c.process_event :present
          c.process_event :focus
          c.process_event :activate
          c.process_event :deactivate
        end
      end
    end



    it 'should highlight' do
      connect true do |redis|
        require "MINT-core"

        DataMapper.finalize

        test_state_flow redis,"Interactor.CIO.Button.reset" ,[["p", "b", "displaying", "d", "released", "init_js"],"displayed","highlighted"] do

          b = MINT::Button.create(:name=>"reset",:height =>60, :width => 200, :x=>380, :y => 150, :states=>[:positioned], :highlightable =>true)
          b.process_event :display
          b.process_event :highlight


        end
      end


    end
  end

end
