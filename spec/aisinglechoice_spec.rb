require "spec_helper"

describe 'SingleChoice' do

  include EventMachine::SpecHelper

  before :all do
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

    connection_options = { :adapter => "redis"}
    DataMapper.setup(:default, connection_options)

    class ::Helper
      def self.create_structure
        MINT::AISingleChoice.create(:name => "choice", :children => "element_1|element_2|element_3|element_4")
        MINT::AISingleChoiceElement.create(:name => "element_1", :parent=>"choice")
        MINT::AISingleChoiceElement.create(:name => "element_2", :parent=>"choice")
        MINT::AISingleChoiceElement.create(:name => "element_3", :parent=>"choice")
        MINT::AISingleChoiceElement.create(:name => "element_4", :parent=>"choice")
        MINT::AISingleChoice.first
      end

      def self.initialize_main_structure
        @sc = Helper.create_structure
        AUIControl.organize(@sc,nil,0)

        @sc.process_event(:present).should == [:defocused, :listing]
        @sc.states.should == [:defocused, :listing]
      end
    end

    connect do |redis|
      require "MINT-core"

      DataMapper.finalize
      DataMapper::Model.raise_on_save_failure = true
    end
  end

  describe "child relations" do
    it 'should deactivate other chosen elements on choose' do
      connect do |redis|
        Helper.initialize_main_structure
        @e1 = MINT::AISingleChoiceElement.first(:name => "element_1")
        @e2 = MINT::AISingleChoiceElement.first(:name => "element_2")

        @e1.process_event(:focus).should == [:focused, :listed]
        @e1.new_states.should == [:focused]
        @e2.process_event(:focus).should == [:focused, :listed]
        @e2.new_states.should == [:focused]

        @e1.process_event(:choose).should == [:focused, :chosen]
        @e2.process_event(:choose).should == [:focused, :chosen]

        # TODO: state actualization should be done withnt :suspend, out re-querying?
        @e1 = MINT::AISingleChoiceElement.first(:name => "element_1")
        @e1.states.should == [:focused, :listed]
      end
    end

    it 'should accept drag event in listed or chosen' do
      connect do |redis|
        Helper.initialize_main_structure
        @e1 = MINT::AISingleChoiceElement.first(:name => "element_1")

        @e1.process_event(:focus).should == [:focused, :listed]
        @e1.states.should == [:focused, :listed]

        @e1.process_event(:drag).should == [:focused, :dragging]
        @e1.states.should == [:focused, :dragging]

        @e1.process_event(:drop).should == [:focused, :listed]
        @e1.states.should == [:focused, :listed]

        @e1.process_event(:choose).should == [:focused, :chosen]
        @e1.states.should == [:focused, :chosen]

        @e1.process_event(:drag).should == [:focused, :dragging]
        @e1.states.should == [:focused, :dragging]

        @e1.process_event(:drop).should == [:focused, :listed]
        @e1.states.should == [:focused, :listed]

      end
  end

    it 'should hide child elements on suspend' do
      connect do |redis|
        Helper.initialize_main_structure

        sc =MINT::AISingleChoice.first(:name => "choice")
        sc.process_event(:suspend).should == [:suspended]
        e1 = MINT::AISingleChoiceElement.first(:name => "element_1")
        e1.states.should == [:suspended]
      end
    end

    it 'should hide if suspend is called from parent AIContainer' do
      connect do |redis|
        Helper.initialize_main_structure

        sc = MINT::AISingleChoice.first(:name => "choice")

        aic = MINT::AIContainer.create(:name => "container", :states=>[:defocused], :children => "choice")

        aic.process_event(:suspend).should == [:suspended]
        e1 = MINT::AISingleChoiceElement.first(:name => "element_1")
        e1.states.should == [:suspended]
      end
    end

    it "should sync suspend to CUI"   do
      connect do |redis|
        #TODO Find out from where these RadioButtonGroup states come from
        Helper.initialize_main_structure

        MINT::RadioButtonGroup.create(:name =>"choice", :states => [:presenting,:listed])
        MINT::Selectable.create(:name =>"element_1", :states =>[:displayed,:listed])
        MINT::Selectable.create(:name =>"element_2", :states =>[:displayed,:listed])
        MINT::Selectable.create(:name =>"element_3", :states =>[:displayed,:listed])
        MINT::Selectable.create(:name =>"element_4", :states =>[:displayed,:listed])

        aic = MINT::AIContainer.create(:name => "container", :states=>[:defocused], :children => "choice")

        aic.process_event(:suspend).should == [:suspended]
        e1 = MINT::AISingleChoiceElement.first(:name => "element_1")
        e1.states.should == [:suspended]

        s4 = MINT::Selectable.first(:name =>"element_4")
        s4.states.should == [:hidden]
        rbg = MINT::RadioButtonGroup.first(:name=>"choice")
        rbg.states.should == [:hidden]
      end
    end

    it "should remove elements that have been dropped elsewhere"   do
      connect do |redis|
        #TODO Figure out how to make the AISingleChoice.add work again
        Helper.initialize_main_structure

        sc = MINT::AISingleChoice.first(:name => "choice")
        e1 = MINT::AISingleChoiceElement.first(:name => "element_1")
        e1.process_event(:focus)
        e1.process_event(:drag)
        dest = MINT::AISingleChoice.new(:name => "choice_dest")
        AUIControl.organize(dest,nil, 0)
        dest.process_event(:present)
        dest.process_event(:focus)
        dest.process_event(:drop)
        sc.children.length.should == 3
        dest.children.length.should == 1
        p sc.children.inspect
        e1 = MINT::AISingleChoiceElement.first(:name => "element_1").should_not == nil
      end
    end
  end

end
