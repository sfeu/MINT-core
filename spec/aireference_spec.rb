require "spec_helper"

include MINT

describe 'AUI' do
  before :each do
    connection_options = { :adapter => "in_memory"}
    DataMapper.setup(:default, connection_options)
      #    DataMapper.setup(:default, { :adapter => "rinda",:local =>Rinda::TupleSpace.new})
    MINT::AIReference.new(:name=>"ref", :refers =>
        AIO.new(:name => "target")
    ).save

    @a = MINT::AIReference.first
  end

  describe 'AIReference' do
    it 'should initialize with initiated' do
      @a.states.should ==[:initialized]
      @a.new_states.should == [:initialized]
    end
    it 'should refer to correct object' do
      @a.refers.name.should == "target"

    end
  end
end
