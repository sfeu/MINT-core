require "spec_helper"

describe 'AUI' do
    include EventMachine::SpecHelper

    before :all do
      connection_options = { :adapter => "redis"}
      DataMapper.setup(:default, connection_options)

      class ::Helper
        def self.initialize
          AIContainer.create(:name=>"interactive_sheet", :children => [
              AIContainer.create(:name=>"sheets", :children =>[]),
              AISingleChoice.create(:name=>"option", :label=>"Options", :children => [
                  AISingleChoiceElement.create(:name=>"nodding",:label=>"Nodding"),
                  AISingleChoiceElement.create(:name=>"tilting",:label=>"Tilting"),
                  AISingleChoiceElement.create(:name=>"turning",:label=>"Turning")
              ])
          ]).save

          @interactive_sheet = AIContainer.first
          AUIControl.organize(@interactive_sheet,nil,0)
          @interactive_sheet.save!

          @sheets = MINT::AIContainer.first(:name=>"sheets")
          @option = MINT::AISingleChoice.first(:name=>"option")
        end
      end

      connect do |redis|
        require "MINT-core"

        DataMapper.finalize
        DataMapper::Model.raise_on_save_failure = true

      end
    end


  describe 'music sheet' do
    it 'interactive_sheet should recover state after save and reload' do
      connect do |redis|
        Helper.initialize
        @interactive_sheet.states.should == [:organized]
        @interactive_sheet.save!
        b = MINT::AIContainer.first(:name=>"interactive_sheet")
        b.states.should == [:organized]
        b.process_event(:present).should == [:defocused]
      end
    end

    it 'sheets should recover state after save and reload' do
      # @a.process_event(:organize).should ==[:organized]
      @sheets.states.should == [:organized]
      @sheets.new_states.should == [:organized]
      @sheets.process_event(:present).should ==[:defocused]
      @sheets.save!
      sheets =  MINT::AIContainer.first(:name=>"sheets")
      sheets.states.should == [:defocused]
      sheets.process_event(:focus).should == [:focused]
    end

    it 'option list should recover state after save and reload' do
      # @a.process_event(:organize).should ==[:organized]
      @option.states.should == [:organized]
      @option.new_states.should == [:organized]
      @option.process_event(:present).should ==[:defocused, :listing]
      @option.childs.each do |c|
        c.process_event(:focus)
        c.states.should == [:focused, :unchosen]
      end
      @option.save!
      option =  MINT::AISingleChoice.first(:name=>"option")
      option.states.should == [:defocused, :listing]
      option.process_event(:focus).should == [:focused, :listing]
      option.childs.each do |c|
        c.states.should == [:focused, :unchosen]
      end
    end

    it 'lists options should recover state after save and reload' do
      # @a.process_event(:organize).should ==[:organized]
      @option.states.should == [:organized]
      @option.new_states.should == [:organized]
      @option.process_event(:present).should ==[:defocused, :listing]
      #save list
      @option.save!
      #recover one of its children and alter its state
      nodding =  MINT::AISingleChoiceElement.first(:name=>"nodding")
      nodding.states.should == [:defocused, :unchosen]
      nodding.process_event(:choose).should == [:defocused, :chosen]
      #save child
      nodding.save!
      #recover child and check
      nodding =  MINT::AISingleChoiceElement.first(:name=>"nodding")
      nodding.states.should == [:defocused, :chosen]
      #recover another child and alter its state
      tilting =  MINT::AISingleChoiceElement.first(:name=>"tilting")
      tilting.process_event(:focus).should == [:focused, :unchosen]
      #save child
      tilting.save!
      #recover child and check
      tilting = MINT::AISingleChoiceElement.first(:name=>"tilting")
      tilting.states.should == [:focused, :unchosen]
      # choose option tilting, thus unchoosing nodding
      tilting.process_event(:choose)
      tilting.states.should == [:focused, :chosen]
      # recover nodding to see the change made
      nodding = MINT::AISingleChoiceElement.first(:name=>"nodding")
      nodding.states.should == [:defocused, :unchosen]
      #save child
      tilting.save!
      #recover and check
      tilting =  MINT::AISingleChoiceElement.first(:name=>"tilting")
      tilting.states.should == [:focused, :chosen]
    end
  end

  describe "AUI/CUI synchronization" do
    before :each do
      MINT::CIC.create(:name =>"interactive_sheet",:x=>15, :y=>15, :width =>1280, :height => 1000,:layer=>0, :rows=>2, :cols=>1,:states=>[:positioned])
      MINT::SingleHighlight.create(:name => "sheets", :width=>1198, :height => 820,:states=>[:positioned])

      MINT::RadioButtonGroup.create(:name =>"option", :x=>30,:y=>840, :width=>1200, :height => 100,:rows=>1,:cols=>3,:states=>[:positioned])
      MINT::RadioButton.create(:name => "nodding",:x=>40, :y=>850, :width=>200, :height => 80,:states=>[:positioned])
      MINT::RadioButton.create(:name => "tilting",:x=>440, :y=>850,:width=>200, :height => 80,:states=>[:positioned])
      MINT::RadioButton.create(:name => "turning",:x=>840, :y=>850,:width=>200, :height => 80,:states=>[:positioned])
    end

    it "should sync to displayed" do
      @interactive_sheet.process_event(:present)
      @interactive_sheet.states.should == [:defocused]
      MINT::CIC.first(:name=>"interactive_sheet").states.should == [:displayed]
      MINT::SingleHighlight.first(:name=>"sheets").states.should == [:displayed]
      MINT::RadioButtonGroup.first(:name=>"option").states.should == [:displayed]
      MINT::RadioButton.first(:name=>"nodding").states.should == [:displayed, :listed]
      MINT::RadioButton.first(:name=>"tilting").states.should == [:displayed, :listed]
      MINT::RadioButton.first(:name=>"turning").states.should == [:displayed, :listed]
    end

    it "should sync interactive_sheet to highlighted" do
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

    it "should sync sheets to highlighted" do
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

    it "should sync option to highlighted" do
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

    it "should sync only one RadioButton to selected at a time" do
      @interactive_sheet.process_event(:present)

      MINT::AISingleChoiceElement.first(:name=>"nodding").process_event(:choose)

      MINT::AISingleChoiceElement.first(:name=>"nodding").states.should == [:defocused, :chosen]
      MINT::AISingleChoiceElement.first(:name=>"tilting").states.should == [:defocused, :unchosen]
      MINT::AISingleChoiceElement.first(:name=>"turning").states.should == [:defocused, :unchosen]

      MINT::RadioButton.first(:name=>"nodding").states.should == [:displayed, :selected]
      MINT::RadioButton.first(:name=>"tilting").states.should == [:displayed, :listed]
      MINT::RadioButton.first(:name=>"turning").states.should == [:displayed, :listed]
    end

  end

end
