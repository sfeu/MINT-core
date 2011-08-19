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
      @a.process_event(:organize).should ==[:organized]
      @a.states.should == [:organized]
      @a.new_states.should == [:organized]
    end

    it 'should transform first child to presented if presented and rest to suspended' do
      AUIControl.organize(@a,nil,0)
      # @a.process_event(:organize).should ==[:organized]
      @a.states.should == [:organized]
      @a.new_states.should == [:organized]
      @a.process_event(:present).should ==[:defocused]
      children = @a.childs
      children[0].states.should == [:defocused]
      children[1].states.should == [:suspended]
      children[2].states.should == [:suspended]
    end

    it 'should hide the other elements if a child is presented' do
      AUIControl.organize(@a,nil,0)
      @a.process_event(:present).should == [:defocused]

      AIO.first(:name => "e1").states.should == [:defocused]
      AIO.first(:name => "e2").states.should == [:suspended]
      AIO.first(:name => "e3").states.should == [:suspended]

      e3 = AIO.first(:name => "e3")
      e3.states.should ==[:suspended]
      e3.process_event(:present).should == [:defocused]

      AIO.first(:name => "e1").states.should == [:suspended]
      AIO.first(:name => "e2").states.should == [:suspended]
      AIO.first(:name => "e3").states.should == [:defocused]

      e2 = AIO.first(:name => "e2")
      e2.states.should ==[:suspended]
      e2.process_event(:present).should == [:defocused]

      AIO.first(:name => "e1").states.should == [:suspended]
      AIO.first(:name => "e2").states.should == [:defocused]
      AIO.first(:name => "e3").states.should == [:suspended]

    end

    it 'should hide the other elements if a child is presented (using next and prev events)' do
      AUIControl.organize(@a,nil,0)
      @a.process_event(:present).should == [:defocused]

      AIO.first(:name => "e1").states.should == [:defocused]
      AIO.first(:name => "e2").states.should == [:suspended]
      AIO.first(:name => "e3").states.should == [:suspended]

      @a.process_event(:focus).should == [:waiting]
      @a.process_event(:enter).should == [:entered]
      @a.process_event(:next).should == [:entered]

      AIO.first(:name => "e1").states.should == [:suspended]
      AIO.first(:name => "e2").states.should == [:defocused]
      AIO.first(:name => "e3").states.should == [:suspended]

      @a.process_event(:prev).should == [:entered]

      AIO.first(:name => "e1").states.should == [:defocused]
      AIO.first(:name => "e2").states.should == [:suspended]
      AIO.first(:name => "e3").states.should == [:suspended]
    end



  end
end
