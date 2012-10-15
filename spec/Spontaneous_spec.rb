require "spec_helper"

require "em-spec/rspec"


describe 'Spontaneous' do
  include EventMachine::SpecHelper

  before :all do

    connection_options = { :adapter => "redis"}
    DataMapper.setup(:default, connection_options)

    connect do |redis|
      require "MINT-core"
      require "support/redis_connector_monkey_patch"  # TODO dirty patch for a bug that i have not found :(

      class Spontaneous < MINT::Interactor
        def getSCXML
          "#{File.dirname(__FILE__)}/spontaneous.scxml"
        end
      end

      DataMapper.finalize
      DataMapper::Model.raise_on_save_failure = true
    end
  end

  describe 'synchronized with RedisDB' do

    it 'should do the spontaneous transition to positioned' do
      connect  do |redis|
        @a = Spontaneous.create(:name => "test")
        @a.process_event(:position)
        @a.new_states.should == [:positioned, :superstate]
      end
    end
  end
  describe 'synchronized with Redis-PubSub' do
    it 'should do the spontaneous transition to positioned and publish passing of positioning state ' do
      connect true do |redis|

        test_state_flow redis,"Interactor.Spontaneous.test" ,["initialized",["superstate", "positioning"],"positioned"] do

          @a = Spontaneous.create(:name => "test")
          @a.process_event(:position)

        end
      end

    end
  end
end
