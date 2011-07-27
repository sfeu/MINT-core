require "spec_helper"

describe 'SingleChoice' do
  before :each do
    connection_options = { :adapter => "in_memory"}
    DataMapper.setup(:default, connection_options)
    class CallbackContext
      attr_accessor :called

      def initialize
        @called = nil
      end
      def focus_next
        @called = "focus_next"
      end
      def sync_cio_to_displayed
        @called = "sync_cio_to_displayed"
      end
      def sync_cio_to_highlighted
        @called = "sync_cio_to_highlighted"
      end
      def sync_cio_to_listed
        @called = "sync_cio_to_listed"
      end
      def sync_cio_to_hidden
        @caledled = "sync_cio_to_hidden"
      end
      def exists_next
        true
      end
      def exists_prev
        true
      end
    end
    @callback = CallbackContext.new

    @sc =MINT::AISingleChoice.new(:name => "choice",
                                  :childs => [
                                      MINT::AISingleChoiceElement.new(:name => "element_1"),
                                      MINT::AISingleChoiceElement.new(:name => "element_2"),
                                      MINT::AISingleChoiceElement.new(:name => "element_3"),
                                      MINT::AISingleChoiceElement.new(:name => "element_4")]
    )
    AUIControl.organize(@sc,nil, 0)
    @sc.save
  end

  describe "child relations" do
    before :each do
      @sc.process_event(:present).should == [:presented, :listing]
      @sc.states.should == [:presented, :listing]

      @e1 = MINT::AISingleChoiceElement.first(:name => "element_1")
      @e2 = MINT::AISingleChoiceElement.first(:name => "element_2")
      @e3 = MINT::AISingleChoiceElement.first(:name => "element_3")
      @e4 = MINT::AISingleChoiceElement.first(:name => "element_4")

      @e1.process_event(:present)
      @e2.process_event(:present)
      @e3.process_event(:present)
      @e4.process_event(:present)
    end
    it 'should deactivate other chosen elements on choose' do

      @e1.process_event(:focus).should == [:focused, :listed]
      @e1.new_states.should == [:focused]

      @e1.process_event(:choose).should == [:focused, :chosen]
      @e2.process_event(:choose).should == [:presented, :chosen]

      # TODO: state actualization should be done without re-querying?
      @e1 = MINT::AISingleChoiceElement.first(:name => "element_1")
      @e1.states.should == [:focused, :listed]
    end

    it 'should hide child elements on suspend' do
      sc =MINT::AISingleChoice.first(:name => "choice")
      sc.process_event(:suspend).should == [:hidden]
      e1 = MINT::AISingleChoiceElement.first(:name => "element_1")
      e1.states.should == [:hidden, :listed]
    end

    it 'should hide if suspend is called from parent AIC' do
      sc =MINT::AISingleChoice.first(:name => "choice")

      aic = MINT::AIC.create(:name => "container", :states=>[:presented],:childs =>[sc])

      aic.process_event(:suspend).should == [:hidden]
      e1 = MINT::AISingleChoiceElement.first(:name => "element_1")
      e1.states.should == [:hidden,:listed]
    end

    it "should sync suspend to CUI"   do
      MINT::RadioButtonGroup.create(:name =>"choice", :states => [:presenting,:listed])
      MINT::Selectable.create(:name =>"element_1", :states =>[:displayed,:listed])
      MINT::Selectable.create(:name =>"element_2", :states =>[:displayed,:listed])
      MINT::Selectable.create(:name =>"element_3", :states =>[:displayed,:listed])
      MINT::Selectable.create(:name =>"element_4", :states =>[:displayed,:listed])


      sc =MINT::AISingleChoice.first(:name => "choice")

      aic = MINT::AIC.create(:name => "container", :states=>[:presented],:childs =>[sc])

      aic.process_event(:suspend).should == [:hidden]
      e1 = MINT::AISingleChoiceElement.first(:name => "element_1")
      e1.states.should == [:hidden,:listed]

      s4=MINT::Selectable.first(:name =>"element_4")
      s4.states.should ==[:hidden]
      rbg = MINT::RadioButtonGroup.first(:name=>"choice")
      rbg.states.should == [:hidden]
    end

    it "should remove elements that have been dropped elsewhere"   do
      pending("get drop from drag n drop working")
      sc =MINT::AISingleChoice.first(:name => "choice")
      e1 = MINT::AISingleChoiceElement.first(:name => "element_1")
      e1.process_event(:drag)
      #e1.process_event(:drop)
      dest =MINT::AISingleChoice.create(:name => "choice_dest",:states => [:presented,:listing])
      dest.process_event(:drop)
      #dest.childs << e1
      #p dest.childs.save
      sc.childs.length.should ==3
      dest.childs.length.should ==1
      p sc.childs.inspect
      e1 = MINT::AISingleChoiceElement.first(:name => "element_1").should_not == nil

    end
  end

end
