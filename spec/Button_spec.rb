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

        test_state_flow redis,"Interactor.CIO.Button" ,%w(initialized) do

          MINT::Button.create(:name => "test")

        end
      end
    end
    it 'should highlight based on AICommand update to focus' do
      connect true,120 do |redis|

        # Sync CIO to displaying
        o1 = Observation.new(:element =>"Interactor.AIO", :states =>[:presenting],:result=>"aio",:process => :onchange)
        o2 = NegationObservation.new(:element =>"Interactor.CIO", :name =>"aio.name" ,:states =>[:displaying], :result => "cio",:process => :instant )
        a = EventAction.new(:event => :display, :target => "cio")
        m = MINT::SequentialMapping.new(:name=>"Sync CIO to displaying", :observations => [o1,o2],:actions =>[a])
        m.start
        # Sync CIO to highlighted
        o1 = Observation.new(:element =>"Interactor.AIO", :states =>[:focused],:result=>"aio",:process => :onchange)
        o2 = NegationObservation.new(:element =>"Interactor.CIO", :name =>"aio.name" ,:states =>[:highlighted], :result => "cio",:process => :instant )
        a = EventAction.new(:event => :highlight, :target => "cio")
        m = MINT::SequentialMapping.new(:name=>"Sync CIO to highlighted", :observations => [o1,o2],:actions =>[a])
        m.start


        test_state_flow redis,"Interactor.CIO.Button" ,[["p", "displaying", "b", "displayed", "released"],"highlighted"] do
          MINT::Button.create(:name=>"reset",:height =>60, :width => 200, :x=>380, :y => 150, :states=>[:positioned], :highlightable =>true)

          c = MINT::AICommand.create(:name=>"reset", :states=>[:organized])

          c.process_event :present
          c.process_event :focus

        end

      end

    end
    it 'should highlight' do
      connect true do |redis|
        require "MINT-core"

        DataMapper.finalize

        test_state_flow redis,"Interactor.CIO.Button" ,[["p", "displaying", "b", "displayed", "released"],"highlighted"] do

          b = MINT::Button.create(:name=>"reset",:height =>60, :width => 200, :x=>380, :y => 150, :states=>[:positioned], :highlightable =>true)
          b.process_event :display
          b.process_event :highlight


        end
      end


    end
  end

end
