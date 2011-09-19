require "spec_helper"

include MINT
describe 'AUI' do
  before :each do
    connection_options = { :adapter => "in_memory"}
    DataMapper.setup(:default, connection_options)
      #    DataMapper.setup(:default, { :adapter => "rinda",:local =>Rinda::TupleSpace.new})
    AIC.new(:name=>"interactive_sheet", :childs => [
    AIC.new(:name=>"sheets", :childs =>[]),
    AISingleChoice.new(:name=>"option", :label=>"Options", :childs => [
        AISingleChoiceElement.new(:name=>"nodding",:label=>"Nodding"),
        AISingleChoiceElement.new(:name=>"tilting",:label=>"Tilting"),
        AISingleChoiceElement.new(:name=>"turning",:label=>"Turning")
    ])
]).save

    @a = AIC.first
  end

  describe 'music sheet' do
    it 'interactive_sheet should recover state after save and reload' do
      @a.process_event(:organize).should == [:organized]
      @a.save!
      b =  MINT::AIC.first(:name=>"interactive_sheet")
      b.states.should == [:organized]
      b.process_event(:present).should == [:defocused]
    end

    it 'sheets should recover state after save and reload' do
      @a = AIC.first(:name=>"sheets")
      AUIControl.organize(@a,nil,0)
        # @a.process_event(:organize).should ==[:organized]
      @a.states.should == [:organized]
      @a.new_states.should == [:organized]
      @a.process_event(:present).should ==[:defocused]
      @a.childs.each do |c|
        c.states.should == [:defocused, :listing]
      end
      @a.save!
      b =  MINT::AIC.first(:name=>"sheets")
      b.states.should == [:defocused]
      b.process_event(:focus).should == [:focused]
      b.childs.each do |c|
        c.states.should == [:defocused, :unchosen]
      end
    end

    it 'option list should recover state after save and reload' do
      @a = AISingleChoice.first
      AUIControl.organize(@a,nil,0)
        # @a.process_event(:organize).should ==[:organized]
      @a.states.should == [:organized]
      @a.new_states.should == [:organized]
      @a.process_event(:present).should ==[:defocused, :listing]
      @a.childs.each do |c|
        c.process_event(:focus)
        c.states.should == [:focused, :unchosen]
      end
      @a.save!
      b =  MINT::AISingleChoice.first(:name=>"option")
      b.states.should == [:defocused, :listing]
      b.process_event(:focus).should == [:focused, :listing]
      b.childs.each do |c|
        c.states.should == [:focused, :unchosen]
      end
    end

    it 'lists options should recover state after save and reload' do
      #organize and present the whole list and its children
      @a = AISingleChoice.first
      AUIControl.organize(@a,nil,0)
        # @a.process_event(:organize).should ==[:organized]
      @a.states.should == [:organized]
      @a.new_states.should == [:organized]
      @a.process_event(:present).should ==[:defocused, :listing]
      #save list
      @a.save!
      #recover one of its children and alter its state
      b =  MINT::AISingleChoiceElement.first(:name=>"nodding")
      b.states.should == [:defocused, :unchosen]
      b.process_event(:choose).should == [:defocused, :chosen]
      #save child
      b.save!
      #recover child and check
      b =  MINT::AISingleChoiceElement.first(:name=>"nodding")
      b.states.should == [:defocused, :chosen]
      #recover another child and alter its state
      c =  MINT::AISingleChoiceElement.first(:name=>"tilting")
      c.process_event(:focus).should == [:focused, :unchosen]
      #save child
      c.save!
      #recover child and check
      c = MINT::AISingleChoiceElement.first(:name=>"tilting")
      c.states.should == [:focused, :unchosen]
      # choose option tilting, thus unchoosing nodding
      c.process_event(:choose)
      c.states.should == [:focused, :chosen]
      # recover nodding to see the change made
      b = MINT::AISingleChoiceElement.first(:name=>"nodding")
      b.states.should == [:defocused, :unchosen]
      #save child
      c.save!
      #recover and check
      c =  MINT::AISingleChoiceElement.first(:name=>"tilting")
      c.states.should == [:focused, :chosen]
    end
  end
end
