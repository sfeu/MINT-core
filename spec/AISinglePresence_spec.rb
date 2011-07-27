require "spec_helper"

include MINT
describe 'AUI' do
  before :each do
    connection_options = { :adapter => "in_memory"}
    DataMapper.setup(:default, connection_options)
    #    DataMapper.setup(:default, { :adapter => "rinda",:local =>Rinda::TupleSpace.new})
    AISinglePresence.new(:name=>"a", :childs =>[
        AIO.new(:name => "e1"),
        AIO.new(:name => "e2"),
        AIO.new(:name => "e3")
    ]).save

    @a = AISinglePresence.first
  end

  describe 'AISinglePresence' do
    it 'should initialize with initiated' do
      @a.states.should ==[:initialized]
      @a.new_states.should == [:initialized]
    end

    it 'should transform to organizing state ' do
      @a.process_event(:organized).should ==[:organized]
      @a.states.should == [:organized]
      @a.new_states.should == [:organized]
    end

    it 'should transform first child to presented if presented and rest to hidden' do
      AUIControl.organize(@a,nil,0)
      # @a.process_event(:organized).should ==[:organized]
      @a.states.should == [:organized]
      @a.new_states.should == [:organized]
      @a.process_event(:present).should ==[:presented,:listing]
      children = @a.childs
      children[0].states.should == [:presented]
      children[1].states.should == [:hidden]
      children[2].states.should == [:hidden]
    end

    it 'should hide the other elements if a child is presented' do
      AUIControl.organize(@a,nil,0)
      @a.process_event(:present).should == [:presented,:listing]

      AIO.first(:name => "e1").states.should == [:presented]
      AIO.first(:name => "e2").states.should == [:hidden]
      AIO.first(:name => "e3").states.should == [:hidden]

      e3 = AIO.first(:name => "e3")
      e3.states.should ==[:hidden]
      e3.process_event(:present).should == [:presented]

      AIO.first(:name => "e1").states.should == [:hidden]
      AIO.first(:name => "e2").states.should == [:hidden]
      AIO.first(:name => "e3").states.should == [:presented]

      e2 = AIO.first(:name => "e2")
      e2.states.should ==[:hidden]
      e2.process_event(:present).should == [:presented]

      AIO.first(:name => "e1").states.should == [:hidden]
      AIO.first(:name => "e2").states.should == [:presented]
      AIO.first(:name => "e3").states.should == [:hidden]

    end
  end
end
