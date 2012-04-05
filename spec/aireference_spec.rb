require "spec_helper"

include MINT

describe 'AIReference with refers' do
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

    it 'should focus referred object' do
      #Todo ask Sebastian about the functioning of AIReference
      @a.process_event(:organize)
      @a.refers.process_event(:organize)
      @a.process_event(:present)
      @a.refers.process_event(:present)
      @a.process_event(:focus)
      @a.refers.states.should == [:focused]
    end

  end

  describe 'AIReference without refers' do
    before :each do
      connection_options = { :adapter => "in_memory"}
      DataMapper.setup(:default, connection_options)
      #    DataMapper.setup(:default, { :adapter => "rinda",:local =>Rinda::TupleSpace.new})
      MINT::AIReference.new(:name=>"ref").save

      @a = MINT::AIReference.first
    end
    it 'should return to defocused in case there is no referred object' do
      @a.process_event(:organize)
      @a.process_event(:present)
      @a.process_event(:focus)
      @a.states.should == [:defocused]
    end
  end

end
