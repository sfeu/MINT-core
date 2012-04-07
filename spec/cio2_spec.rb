require "spec_helper"

require "em-spec/rspec"

describe 'CUI' do
  include EventMachine::SpecHelper

  before :each do
    connection_options = { :adapter => "redis"}
    DataMapper.setup(:default, connection_options)

    DataMapper::Model.raise_on_save_failure = true
    redis = Redis.connect
    redis.flushdb
  end

  describe 'CIO' do

    it 'should accept and save user and device with position event' do

      connect do |redis|
        require "MINT-core"

        DataMapper.finalize

        test_state_flow redis,"Interactor.CIO" ,%w(initialized positioning)

        MINT::CIO.create(:name => "center")
        @c = MINT::CIO.first

        @c.process_event_vars(:position,"testuser","testdevice").should ==[:positioning]
        @c = MINT::CIO.first

        @c.user.should =="testuser"
        @c.device.should == "testdevice"


      end
    end
  end
end