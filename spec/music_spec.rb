require "spec_helper"

describe 'AUI' do
  include EventMachine::SpecHelper

  before :all do
    class ::Helper
      def self.create_structure
        MINT::AIContainer.create(:name=>"interactive_sheet", :children => "sheets|option")
        MINT::AIContainer.create(:name=>"sheets", :children => "", :parent => "interactive_sheet")
        MINT::AISingleChoice.create(:name=>"option", :children => "nodding|tilting|turning", :parent => "interactive_sheet")
        MINT::AISingleChoiceElement.create(:name=>"nodding",:text=>"Nodding", :parent => "option")
        MINT::AISingleChoiceElement.create(:name=>"tilting",:text=>"Tilting", :parent => "option")
        MINT::AISingleChoiceElement.create(:name=>"turning",:text=>"Turning", :parent => "option")
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
      connect(true) do |redis|
        # Sync AIO to focused
        parser = MINT::MappingParser.new
        m = parser.build_from_scxml File.dirname(__FILE__) +"/../lib/MINT-core/model/mim/aisinglechoice_present_to_child_present.xml"
        m.start

        parser = MINT::MappingParser.new
        m = parser.build_from_scxml File.dirname(__FILE__) +"/../lib/MINT-core/model/mim/aio_present_to_cio_display.xml"
        m.start


        check_result = Proc.new {
          @option.children.each do |c|
            c.process_event(:focus)
            c.states.should == [:focused, :unchosen]
          end
          option =  MINT::AISingleChoice.first(:name=>"option")
          option.states.should == [:defocused, :listing]
          option.process_event(:focus).should == [:focused, :listing]
          option.children.each do |c|
            c.states.should == [:focused, :unchosen]
          end
          done
        }


        test_complex_state_flow_w_name redis,[["Interactor.AIO.AIOUT.AIContainer.AISingleChoice","option" ,["initialized","organized",["p", "presenting", "dropping", "wait_for_children", "listing"],"children_finished","defocused"]]],check_result do  |count|
          Helper.create_structure
          Helper.create_structure_CUI
          @interactive_sheet = MINT::AIContainer.first
          AUIControl.organize(@interactive_sheet,nil,0)
          @option = MINT::AISingleChoice.first(:name=>"option")

          @option.states.should == [:organized]
          @option.new_states.should == [:organized]
          @option.process_event(:present).should ==[:wait_for_children, :listing]
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

        #manually set what is usually done by a mapping
        @option.process_event(:present).should ==[:wait_for_children, :listing]
        @option.present_children

        @option.process_event(:children_finished).should ==[:defocused, :listing]


        #recover one of its children and alter its state
        nodding =  MINT::AISingleChoiceElement.first(:name=>"nodding")
        nodding.states.should == [:defocused, :unchosen]
        nodding.process_event(:focus).should == [:focused, :unchosen]
        nodding.process_event(:choose).should == [:focused, :chosen]

        #recover child and check
        nodding =  MINT::AISingleChoiceElement.first(:name=>"nodding")
        nodding.states.should == [:focused, :chosen]

        #recover another child and alter its state
        tilting =  MINT::AISingleChoiceElement.first(:name=>"tilting")
        tilting.process_event(:focus).should == [:focused, :unchosen]

        #recover child and check
        tilting = MINT::AISingleChoiceElement.first(:name=>"tilting")
        tilting.states.should == [:focused, :unchosen]

        # choose option tilting, thus unchoosing nodding
        tilting.process_event(:choose)
        tilting.states.should == [:focused, :chosen]

        # recover nodding to see the change made
        nodding = MINT::AISingleChoiceElement.first(:name=>"nodding")
        nodding.states.should == [:focused, :unchosen]

        #recover and check
        tilting =  MINT::AISingleChoiceElement.first(:name=>"tilting")
        tilting.states.should == [:focused, :chosen]
      end
    end
  end

  describe "AUI/CUI synchronization" do

    it "should sync to displayed" do
      connect true do |redis|

        parser = MINT::MappingParser.new
        m = parser.build_from_scxml File.dirname(__FILE__) +"/../lib/MINT-core/model/mim/aisinglechoice_present_to_child_present.xml"
        m.start

        parser = MINT::MappingParser.new
        m = parser.build_from_scxml File.dirname(__FILE__) +"/../lib/MINT-core/model/mim/aio_present_to_cio_display.xml"
        m.start


        check_result = Proc.new {
          MINT::CIC.first(:name=>"interactive_sheet").states.should == [:displayed]
          MINT::SingleHighlight.first(:name=>"sheets").states.should == [:displayed]
          MINT::RadioButtonGroup.first(:name=>"option").states.should == [:displayed]
          MINT::RadioButton.first(:name=>"nodding").states.should == [:unselected, :displayed]
          MINT::RadioButton.first(:name=>"tilting").states.should == [:unselected, :displayed]
          MINT::RadioButton.first(:name=>"turning").states.should == [:unselected, :displayed]
          done
        }

        test_complex_state_flow_w_name redis,[["Interactor.AIO.AIOUT.AIContainer.AISingleChoice","option" ,["initialized","organized",["p", "presenting", "dropping", "wait_for_children", "listing"],"children_finished","defocused"]]],check_result do  |count|

          Helper.create_structure
          Helper.create_structure_CUI
          @interactive_sheet = MINT::AIContainer.first
          AUIControl.organize(@interactive_sheet,nil,0)
          @interactive_sheet.process_event(:present)
        end
      end
    end

    it "should sync interactive_sheet to highlighted" do
      connect true,10 do |redis|
        parser = MINT::MappingParser.new
        m = parser.build_from_scxml File.dirname(__FILE__) +"/../lib/MINT-core/model/mim/aisinglechoice_present_to_child_present.xml"
        m.start

        parser = MINT::MappingParser.new
        m = parser.build_from_scxml File.dirname(__FILE__) +"/../lib/MINT-core/model/mim/aio_present_to_cio_display.xml"
        m.start

        parser = MINT::MappingParser.new
        m = parser.build_from_scxml File.dirname(__FILE__) +"/../lib/MINT-core/model/mim/aio_focus_to_cio_highlight.xml"
        m.start





        check_result_2 = Proc.new {
          MINT::CIC.first(:name=>"interactive_sheet").states.should == [:highlighted]
          MINT::SingleHighlight.first(:name=>"sheets").states.should == [:displayed]
          MINT::RadioButtonGroup.first(:name=>"option").states.should == [:displayed]
          MINT::RadioButton.first(:name=>"nodding").states.should == [:unselected, :displayed]
          MINT::RadioButton.first(:name=>"tilting").states.should == [:unselected, :displayed]
          MINT::RadioButton.first(:name=>"turning").states.should == [:unselected, :displayed]
          done
        }

        check_result = Proc.new {
          test_complex_state_flow_w_name redis,[["Interactor.CIO.CIC","interactive_sheet" ,["highlighted"]]],check_result_2 do  |count|
            @interactive_sheet = MINT::AIContainer.first(:name => "interactive_sheet")
            @interactive_sheet.process_event(:focus)
          end
        }

        test_complex_state_flow_w_name redis,[["Interactor.AIO.AIOUT.AIContainer.AISingleChoice","option" ,["initialized","organized",["p", "presenting", "dropping", "wait_for_children", "listing"],"children_finished","defocused"]]],check_result do  |count|
          Helper.create_structure
          Helper.create_structure_CUI
          @interactive_sheet = MINT::AIContainer.first
          AUIControl.organize(@interactive_sheet,nil,0)
          @interactive_sheet.process_event(:present)
        end
      end
    end

    it "should sync interactive_sheet to highlighted" do
      connect true do |redis|
        parser = MINT::MappingParser.new
        m = parser.build_from_scxml File.dirname(__FILE__) +"/../lib/MINT-core/model/mim/aisinglechoice_present_to_child_present.xml"
        m.start

        parser = MINT::MappingParser.new
        m = parser.build_from_scxml File.dirname(__FILE__) +"/../lib/MINT-core/model/mim/aio_present_to_cio_display.xml"
        m.start

        parser = MINT::MappingParser.new
        m = parser.build_from_scxml File.dirname(__FILE__) +"/../lib/MINT-core/model/mim/aio_focus_to_cio_highlight.xml"
        m.start

        check_result_2 = Proc.new {
          MINT::CIC.first(:name=>"interactive_sheet").states.should == [:highlighted]
          MINT::SingleHighlight.first(:name=>"sheets").states.should == [:displayed]
          MINT::RadioButtonGroup.first(:name=>"option").states.should == [:displayed]
          MINT::RadioButton.first(:name=>"nodding").states.should == [:unselected, :displayed]
          MINT::RadioButton.first(:name=>"tilting").states.should == [:unselected, :displayed]
          MINT::RadioButton.first(:name=>"turning").states.should == [:unselected, :displayed]
          done
        }

        check_result = Proc.new {
          test_complex_state_flow_w_name redis,[["Interactor.CIO.CIC","interactive_sheet" ,["highlighted"]]],check_result_2 do  |count|
            @sheets = MINT::AIContainer.first(:name=>"interactive_sheet")
            @sheets.process_event(:focus)
          end
        }

        test_complex_state_flow_w_name redis,[["Interactor.AIO.AIOUT.AIContainer.AISingleChoice","option" ,["initialized","organized",["p", "presenting", "dropping", "wait_for_children", "listing"],"children_finished","defocused"]]],check_result do  |count|

          Helper.create_structure
          Helper.create_structure_CUI
          @interactive_sheet = MINT::AIContainer.first
          AUIControl.organize(@interactive_sheet,nil,0)
          @interactive_sheet.process_event(:present)
        end

      end
    end



    it "should sync only one RadioButton to selected at a time" do
      connect true do |redis|

        parser = MINT::MappingParser.new
        m = parser.build_from_scxml File.dirname(__FILE__) +"/../lib/MINT-core/model/mim/aisinglechoice_present_to_child_present.xml"
        m.start

        parser = MINT::MappingParser.new
        m = parser.build_from_scxml File.dirname(__FILE__) +"/../lib/MINT-core/model/mim/aio_present_to_cio_display.xml"
        m.start

        parser = MINT::MappingParser.new
        m = parser.build_from_scxml File.dirname(__FILE__) +"/../lib/MINT-core/model/mim/aio_focus_to_cio_highlight.xml"
        m.start

        check_result_2 = Proc.new {
          MINT::AISingleChoiceElement.first(:name=>"nodding").process_event(:choose)
          MINT::AISingleChoiceElement.first(:name=>"nodding").states.should == [:focused, :chosen]
          MINT::AISingleChoiceElement.first(:name=>"tilting").states.should == [:defocused, :unchosen]
          MINT::AISingleChoiceElement.first(:name=>"turning").states.should == [:defocused, :unchosen]


          MINT::RadioButton.first(:name=>"nodding").states.should == [:unselected, :highlighted]
          MINT::RadioButton.first(:name=>"tilting").states.should == [:unselected, :displayed]
          MINT::RadioButton.first(:name=>"turning").states.should == [:unselected, :displayed]

          done
        }

        check_result = Proc.new {
          test_complex_state_flow_w_name redis,[["Interactor.CIO.RadioButton","nodding" ,["highlighted"]]],check_result_2 do  |count|
            MINT::AISingleChoiceElement.first(:name=>"nodding").process_event(:focus)
          end
        }

        test_complex_state_flow_w_name redis,[["Interactor.AIO.AIOUT.AIContainer.AISingleChoice","option" ,["initialized","organized",["p", "presenting", "dropping", "wait_for_children", "listing"],"children_finished","defocused"]]],check_result do  |count|
          Helper.create_structure
          Helper.create_structure_CUI
          @interactive_sheet = MINT::AIContainer.first
          AUIControl.organize(@interactive_sheet,nil,0)

          @interactive_sheet.process_event(:present)
        end
      end
    end

  end

end
