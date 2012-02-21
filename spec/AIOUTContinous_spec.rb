require "spec_helper"

describe 'AUI' do
  before :each do
    connection_options = { :adapter => "in_memory"}
    DataMapper.setup(:default, connection_options)

    require "MINT-core"
    redis = Redis.connect
    redis.flushdb

    DataMapper.finalize

    MINT2::AIOUTContinous.new(:name=>"a").save
    @a = MINT2::AIOUTContinous.first
    DataMapper::Model.raise_on_save_failure = true
  end

  describe 'AIOUTContinous' do
    it 'should initialize with initiated' do
      @a.states.should ==[:initialized]
      @a.new_states.should == [:initialized]
    end

    it 'should transform to organizing state ' do
      @a.process_event(:organize).should ==[:organized]
      @a.states.should == [:organized]
      @a.new_states.should == [:organized]
    end

    it 'should transform to progressing state ' do
      @a.process_event(:organize).should ==[:organized]
      @a.process_event(:present).should ==[:defocused, :waiting]
      @a.process_event(:focus).should ==[:focused, :waiting]

      @a.process_event(:move).should ==[:defocused, :progressing]
    end

  end
end
