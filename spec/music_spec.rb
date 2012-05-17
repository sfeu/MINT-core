require "spec_helper"

describe 'AUI' do
    include EventMachine::SpecHelper

    before :all do
      class ::Helper
        def self.create_structure
          MINT::AIContainer.create(:name=>"interactive_sheet", :children => "sheets|option")
          MINT::AIContainer.create(:name=>"sheets", :children => "")
          MINT::AISingleChoice.create(:name=>"option", :label=>"Options", :children => "nodding|tilting|turning")
          MINT::AISingleChoiceElement.create(:name=>"nodding",:label=>"Nodding")
          MINT::AISingleChoiceElement.create(:name=>"tilting",:label=>"Tilting")
          MINT::AISingleChoiceElement.create(:name=>"turning",:label=>"Turning")
        end

        def self.create_structure_CUI
          MINT::CIC.create(:name =>"interactive_sheet",:x=>15, :y=>15, :width =>1280, :height => 1000,:layer=>0, :rows=>2, :cols=>1,:states=>[:positioned])
          MINT::SingleHighlight.create(:name => "sheets", :width=>1198, :height => 820,:states=>[:positioned])
          MINT::RadioButtonGroup.create(:name =>"option", :x=>30,:y=>840, :width=>1200, :height => 100,:rows=>1,:cols=>3,:states=>[:positioned])
          MINT::RadioButton.create(:name => "nodding",:x=>40, :y=>850, :width=>200, :height => 80,:states=>[:positioned])
          MINT::RadioButton.create(:name => "tilting",:x=>440, :y=>850,:width=>200, :height => 80,:states=>[:positioned])
          MINT::RadioButton.create(:name => "turning",:x=>840, :y=>850,:width=>200, :height => 80,:states=>[:positioned])
        end
      end

      connection_options = { :adapter => "redis"}
      DataMapper.setup(:default, connection_options)

      connect do |redis|
        require "MINT-core"

        DataMapper.finalize
        DataMapper::Model.raise_on_save_failure = true

      end
    end


=begin
    @interactive_sheet = MINT::AIContainer.first
    AUIControl.organize(@interactive_sheet,nil,0)
    @interactive_sheet.save!

    @sheets = MINT::AIContainer.first(:name=>"sheets")
    @option = MINT::AISingleChoice.first(:name=>"option")
=end

  describe 'music sheet' do
    it 'interactive_sheet should recover state after save and reload' do
      connect do |redis|
        Helper.create_structure
        @interactive_sheet = MINT::AIContainer.first
        AUIControl.organize(@interactive_sheet,nil,0)

        @interactive_sheet.states.should == [:organized]
        b = MINT::AIContainer.first(:name=>"interactive_sheet")
        b.states.should == [:organized]
        b.process_event(:present).should == [:defocused]
      end
    end

    it 'sheets should recover state after save and reload' do
      connect do |redis|
        Helper.create_structure
        @interactive_sheet = MINT::AIContainer.first
        AUIControl.organize(@interactive_sheet,nil,0)
        @sheets = MINT::AIContainer.first(:name=>"sheets")

        @sheets.states.should == [:organized]
        @sheets.new_states.should == [:organized]
        @sheets.process_event(:present).should ==[:defocused]
        sheets =  MINT::AIContainer.first(:name=>"sheets")
        sheets.states.should == [:defocused]
        sheets.process_event(:focus).should == [:focused]
      end
    end

    it 'option list should recover state after save and reload' do
      connect do |redis|
        Helper.create_structure
        @interactive_sheet = MINT::AIContainer.first
        AUIControl.organize(@interactive_sheet,nil,0)
        @option = MINT::AISingleChoice.first(:name=>"option")

        @option.states.should == [:organized]
        @option.new_states.should == [:organized]
        @option.process_event(:present).should ==[:defocused, :listing]
        @option.children.each do |c|
          c.process_event(:focus)
          c.states.should == [:focused, :listed]
        end
        option =  MINT::AISingleChoice.first(:name=>"option")
        option.states.should == [:defocused, :listing]
        option.process_event(:focus).should == [:focused, :listing]
        option.children.each do |c|
          c.states.should == [:focused, :listed]
        end
      end
    end

    it 'lists options should recover state after save and reload' do
      connect do |redis|
        Helper.create_structure
        @interactive_sheet = MINT::AIContainer.first
        AUIControl.organize(@interactive_sheet,nil,0)
        @option = MINT::AISingleChoice.first(:name=>"option")

        @option.states.should == [:organized]
        @option.new_states.should == [:organized]
        @option.process_event(:present).should ==[:defocused, :listing]

        #recover one of its children and alter its state
        nodding =  MINT::AISingleChoiceElement.first(:name=>"nodding")
        nodding.states.should == [:defocused, :listed]
        nodding.process_event(:focus).should == [:focused, :listed]
        nodding.process_event(:choose).should == [:focused, :chosen]

        #recover child and check
        nodding =  MINT::AISingleChoiceElement.first(:name=>"nodding")
        nodding.states.should == [:focused, :chosen]

        #recover another child and alter its state
        tilting =  MINT::AISingleChoiceElement.first(:name=>"tilting")
        tilting.process_event(:focus).should == [:focused, :listed]

        #recover child and check
        tilting = MINT::AISingleChoiceElement.first(:name=>"tilting")
        tilting.states.should == [:focused, :listed]

        # choose option tilting, thus unchoosing nodding
        tilting.process_event(:choose)
        tilting.states.should == [:focused, :chosen]

        # recover nodding to see the change made
        nodding = MINT::AISingleChoiceElement.first(:name=>"nodding")
        nodding.states.should == [:defocused, :listed]

        #recover and check
        tilting =  MINT::AISingleChoiceElement.first(:name=>"tilting")
        tilting.states.should == [:focused, :chosen]
      end
    end
  end

  describe "AUI/CUI synchronization" do

    it "should sync to displayed" do
      connect do |redis|
        Helper.create_structure
        Helper.create_structure_CUI
        @interactive_sheet = MINT::AIContainer.first
        AUIControl.organize(@interactive_sheet,nil,0)

        @interactive_sheet.process_event(:present)
        @interactive_sheet.states.should == [:defocused]
        MINT::CIC.first(:name=>"interactive_sheet").states.should == [:displayed]
        MINT::SingleHighlight.first(:name=>"sheets").states.should == [:displayed]
        MINT::RadioButtonGroup.first(:name=>"option").states.should == [:displayed]
        MINT::RadioButton.first(:name=>"nodding").states.should == [:displayed, :listed]
        MINT::RadioButton.first(:name=>"tilting").states.should == [:displayed, :listed]
        MINT::RadioButton.first(:name=>"turning").states.should == [:displayed, :listed]
      end
    end

    it "should sync interactive_sheet to highlighted" do
      connect do |redis|
        Helper.create_structure
        Helper.create_structure_CUI
        @interactive_sheet = MINT::AIContainer.first
        AUIControl.organize(@interactive_sheet,nil,0)

        @interactive_sheet.process_event(:present)
        @interactive_sheet.process_event(:focus)
        @interactive_sheet.states.should == [:focused]
        MINT::CIC.first(:name=>"interactive_sheet").states.should == [:highlighted]
        MINT::SingleHighlight.first(:name=>"sheets").states.should == [:displayed]
        MINT::RadioButtonGroup.first(:name=>"option").states.should == [:displayed]
        MINT::RadioButton.first(:name=>"nodding").states.should == [:displayed, :listed]
        MINT::RadioButton.first(:name=>"tilting").states.should == [:displayed, :listed]
        MINT::RadioButton.first(:name=>"turning").states.should == [:displayed, :listed]
      end
    end

    it "should sync sheets to highlighted" do
      connect do |redis|
        Helper.create_structure
        Helper.create_structure_CUI
        @interactive_sheet = MINT::AIContainer.first
        AUIControl.organize(@interactive_sheet,nil,0)

        @interactive_sheet.process_event(:present)
        @sheets = MINT::AIContainer.first(:name=>"sheets")
        @sheets.process_event(:focus)
        @sheets.states.should == [:focused]
        MINT::CIC.first(:name=>"interactive_sheet").states.should == [:displayed]
        MINT::SingleHighlight.first(:name=>"sheets").states.should == [:highlighted]
        MINT::RadioButtonGroup.first(:name=>"option").states.should == [:displayed]
        MINT::RadioButton.first(:name=>"nodding").states.should == [:displayed, :listed]
        MINT::RadioButton.first(:name=>"tilting").states.should == [:displayed, :listed]
        MINT::RadioButton.first(:name=>"turning").states.should == [:displayed, :listed]
      end
    end

    it "should sync option to highlighted" do
      connect do |redis|
        Helper.create_structure
        Helper.create_structure_CUI
        @interactive_sheet = MINT::AIContainer.first
        AUIControl.organize(@interactive_sheet,nil,0)

        @interactive_sheet.process_event(:present)
        @sheets = MINT::AIContainer.first(:name=>"sheets")
        @option = MINT::AISingleChoice.first(:name=>"option")
        @option.process_event(:focus)
        @option.states.should == [:focused, :listing]
        MINT::CIC.first(:name=>"interactive_sheet").states.should == [:displayed]
        MINT::SingleHighlight.first(:name=>"sheets").states.should == [:displayed]
        MINT::RadioButtonGroup.first(:name=>"option").states.should == [:highlighted]
        MINT::RadioButton.first(:name=>"nodding").states.should == [:displayed, :listed]
        MINT::RadioButton.first(:name=>"tilting").states.should == [:displayed, :listed]
        MINT::RadioButton.first(:name=>"turning").states.should == [:displayed, :listed]
      end
    end

    it "should sync only one RadioButton to selected at a time" do
      connect do |redis|
        Helper.create_structure
        Helper.create_structure_CUI
        @interactive_sheet = MINT::AIContainer.first
        AUIControl.organize(@interactive_sheet,nil,0)

        @interactive_sheet.process_event(:present)

        MINT::AISingleChoiceElement.first(:name=>"nodding").process_event(:focus)
        MINT::AISingleChoiceElement.first(:name=>"nodding").process_event(:choose)

        MINT::AISingleChoiceElement.first(:name=>"nodding").states.should == [:defocused, :chosen]
        MINT::AISingleChoiceElement.first(:name=>"tilting").states.should == [:defocused, :listed]
        MINT::AISingleChoiceElement.first(:name=>"turning").states.should == [:defocused, :listed]

        MINT::RadioButton.first(:name=>"nodding").states.should == [:displayed, :selected]
        MINT::RadioButton.first(:name=>"tilting").states.should == [:displayed, :listed]
        MINT::RadioButton.first(:name=>"turning").states.should == [:displayed, :listed]
      end
    end

  end

end
