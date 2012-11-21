require "spec_helper"
require "em-spec/rspec"

def create_scenario
  include MINT

  @aui = MINT::AIContainer.create(:name=>"RecipeFinder",
                            :children => "RecipeFinder_label|RecipeFinder_description|RecipeFilter|RecipeSelection")
  MINT::AIReference.create(:name=>"RecipeFinder_label",:parent =>"RecipeFinder",:text=>"Willkommen")
  MINT::AIContext.create(:name=>"RecipeFinder_description",:parent =>"RecipeFinder",:text=>"Willkommen beim 4 Sterne Koch Assistenten.")
  MINT::AIContainer.create(:name=>"RecipeFilter",:parent =>"RecipeFinder",
                     :children => "RecipeFilter_label|RecipeFilter_description|RecipeCuisine|RecipeCategory|RecipeCalories")
  MINT::AIReference.create(:name=>"RecipeFilter_label",:parent =>"RecipeFilter",:text=>"Suchkriterien")
  MINT::AIContext.create(:name=>"RecipeFilter_description",:parent =>"RecipeFilter",:text=>"In diesem Feld koennen Sie mit genauen Angaben zu Ihrem Gericht-Wunsch die Suche nach Ihrem Rezeptvorschlag eingrenzen.")
  MINT::AIContainer.create(:name=>"RecipeCuisine",:parent =>"RecipeFilter",
                     :children => "RecipeCuisine_label|RecipeCuisine_description|RecipeCuisine_choice")
  MINT::AIReference.create(:name=>"RecipeCuisine_label",:parent =>"RecipeCuisine",:text=>"Nationale Kueche")
  MINT::AIContext.create(:name=>"RecipeCuisine_description",:parent =>"RecipeCuisine",:text=>"Welche nationale Kueche waehlen Sie? ")
  MINT::AIMultiChoice.create(:name=>"RecipeCuisine_choice",:parent =>"RecipeCuisine",
                       :children => "French|German|Italian|Chinese")
  MINT::AIChoiceElement.create(:name => "French", :parent =>"RecipeCuisine_choice",:text =>"Franzoesisch")
  MINT::AIChoiceElement.create(:name => "German",:parent =>"RecipeCuisine_choice",:text =>"Deutsch")
  MINT::AIChoiceElement.create(:name => "Italian",:parent =>"RecipeCuisine_choice",:text =>"Italienisch")
  MINT::AIChoiceElement.create(:name => "Chinese",:parent =>"RecipeCuisine_choice",:text =>"Chinesisch")

  MINT::AIContainer.create(:name=>"RecipeCategory",:parent =>"RecipeFilter",
                     :children => "RecipeCategory_label|RecipeCategory_description|RecipeCategory_choice")
  MINT::AIReference.create(:name=>"RecipeCategory_label",:parent =>"RecipeCategory",:text=>"Menueart ")
  MINT::AIContext.create(:name=>"RecipeCategory_description",:parent =>"RecipeCategory",:text=>" Welche Menueart moechten Sie kochen? ")
  MINT::AIMultiChoice.create(:name=>"RecipeCategory_choice",:parent =>"RecipeCategory",
                       :children => "Main|Pastry|Dessert|Starter")
  MINT::AIChoiceElement.create(:name => "Main", :parent =>"RecipeCategory_choice",:text =>"Hauptgericht")
  MINT::AIChoiceElement.create(:name => "Pastry",:parent =>"RecipeCategory_choice",:text =>"Gebaeck")
  MINT::AIChoiceElement.create(:name => "Dessert",:parent =>"RecipeCategory_choice",:text =>"Nachtisch")
  MINT::AIChoiceElement.create(:name => "Starter",:parent =>"RecipeCategory_choice",:text =>"Vorspeise")

  MINT::AIContainer.create(:name=>"RecipeCalories",:parent =>"RecipeFilter",
                     :children => "RecipeCalories_label|RecipeCalories_description|RecipeCalories_choice")
  MINT::AIReference.create(:name=>"RecipeCalories_label",:parent =>"RecipeCalories",:text=>"gesundheitsbewusst ")
  MINT::AIContext.create(:name=>"RecipeCalories_description",:parent =>"RecipeCalories",:text=>" Wollen Sie gesundheitsbewusst kochen? ")
  MINT::AISingleChoice.create(:name=>"RecipeCalories_choice",:parent =>"RecipeCalories",
                        :children => "Diet|LowFat|NotRelevant")
  MINT::AIChoiceElement.create(:name => "Diet", :text =>"Hauptgericht",:parent =>"RecipeCalories_choice")
  MINT::AIChoiceElement.create(:name => "LowFat",:text =>"Gebaeck",:parent =>"RecipeCalories_choice")
  MINT::AIChoiceElement.create(:name => "NotRelevant",:text =>"Nachtisch",:parent =>"RecipeCalories_choice")


  MINT::AIContainer.create(:name =>"RecipeSelection",:parent =>"RecipeFinder",
                     :children => "RecipeSelection_label|RecipeSelection_description|FoundRecipes|Start")
  MINT::AIReference.create(:name=>"RecipeSelection_label",:text=>"Rezeptdetails",:parent =>"RecipeSelection")
  MINT::AIContext.create(:name=>"RecipeSelection_description",:parent =>"RecipeSelection",:text=>"Hier werden Ihre Rezeptvorschlaege mit den Details angezeigt und Sie koennen bestimmen, fuer wieviele Personen das Rezept berechnet werden soll.")
  MINT::AISingleChoice.create(:name=>"FoundRecipes",:parent =>"RecipeSelection",
                        :children => "Schweinebraten|Lammkotletts|Spagetti")
  MINT::AIChoiceElement.create(:name => "Schweinebraten", :text =>"Schweinebraten",:parent =>"FoundRecipes")
  MINT::AIChoiceElement.create(:name => "Lammkotletts",:text =>"Lammkotletts",:parent =>"FoundRecipes")
  MINT::AIChoiceElement.create(:name => "Spagetti",:text =>"Spagetti",:parent =>"FoundRecipes")
  MINT::AICommand.create(:name=>"Start",:text=>"Kochassistent starten",:parent =>"RecipeSelection")

end

describe 'AUI-Agent' do

  include EventMachine::SpecHelper

  before :all do
    connection_options = { :adapter => "redis"}
    DataMapper.setup(:default, connection_options)

    connect do |redis|
      require "MINT-core"

      DataMapper.finalize
      DataMapper::Model.raise_on_save_failure = true
    end
  end

  describe 'organizing' do

    it 'should save correctly' do
      pending "no longer needed "
      class P < MINT::Interactor

#        belongs_to :c
        belongs_to  :parent, 'C',
                    :parent_key => [ :id ],       # in the remote model (Blog)
                    :child_key  => [ :c_id ],  # local to this model (Post)
                    :required   => true

        has 1, :next, P
        has 1, :previous, P
      end

      class C < P
        has n, :children, 'P',
            :parent_key => [ :id ],      # local to this model (Blog)
            :child_key  => [ :c_id ]  # in the remote model (Post)

      end

      t2 = P.new(:name=>"Test2")
      t1 = C.new(:name=>"Test1", :childs =>[t2],:next=>t2)
      t2.previous = t1

      t1.childs[0].parent.name.should =="Test1"

      t1.save!


      P.first(:name=>"Test2").parent.name.should == "Test1"
      P.first(:name=>"Test2").previous.name.should == "Test1"
      C.first(:name=>"Test1").next.name.should == "Test2"
    end

    it "should organize parental relations correctly" do
      connect do |redis|
        aic = MINT::AIContainer.create(:name =>"AIContainer", :children => "AIO")
        MINT::AIO.create(:name=>"AIO",:parent =>"AIContainer")
        aic.save!

        MINT::AIO.first(:name=>"AIO").parent.name.should == "AIContainer"
      end
    end

    it "should organize parental relations correctly 2" do
      connect do |redis|
        MINT::AIContainer.create(:name=>"RecipeFinder",
                           :children => "RecipeFinder_label")
        MINT::AIReference.create(:name=>"RecipeFinder_label",:parent =>"RecipeFinder",:text=>"Willkommen")

        MINT::AIO.first(:name=>"RecipeFinder_label").parent.name.should == "RecipeFinder"
      end
    end

    it "should organize parental relations correctly 3" do
      connect do |redis|
        create_scenario
        MINT::AIO.first(:name=>"RecipeFinder_label").parent.name.should == "RecipeFinder"
      end
    end

    it 'should organize with parental relationships 4' do
      connect do |redis|
        create_scenario
        MINT::AIChoiceElement.first(:name => "Main").parent.name.should ==  "RecipeCategory_choice"
      end
    end

    it 'should support next navigation' do
      connect do |redis|
        create_scenario
        AUIControl.organize(@aui)
        @aui.save!#.should==true
        @aui.next.name.should=="RecipeFinder_description" # a label does forward the navigation
        @aui.next.next.next.next.name.should=="RecipeCuisine"


        n = MINT::AIO.first(:name => "RecipeFinder")
        10.times {n=n.next}
        n.name.should=="Chinese"
        12.times {n=n.next}
        n.name.should=="LowFat"
        8.times {n=n.next}
        n.name.should=="Start"
      end      end

    it "should support previous navigation" do
      connect do |redis|
        create_scenario
        AUIControl.organize(@aui)
        @aui.save!

        n = MINT::AIO.first(:name => "Start")
                   #    n = @aui #
                   # 36.times {n=n.next}
                   #n.name.should=="Start"

        10.times {n=n.previous}
        n.name.should=="RecipeCalories_choice"
        4.times {n=n.previous}
        n.name.should=="Dessert"
        16.times {n=n.previous}
        n.name.should=="RecipeFinder"
      end      end

    it 'should support next navigation in organize 2' do
      pending "currently only one mode is supported"
      connect do |redis|
        create_scenario
        AUIControl.organize2(@aui)
        # @aui.save#.should==true
        # @aui.next.name.should=="RecipeFinder"
        # @aui.next.next.next.next.name.should=="RecipeFinder"


        n = MINT::AIO.first(:name => "RecipeFinder_label")
        3.times {n=n.next}
        n.name.should=="RecipeSelection"

        n = MINT::AIO.first(:name => "RecipeCalories_label")
        2.times {n=n.next}
        n.name.should=="RecipeCalories_choice"

#     n = AIO.first(:name => "Start")
#      7.times {n=n.next} 
#      n.name.should=="FoundRecipes"
      end      end

    it "should support previous navigation in organize 2" do
      pending "currently only one mode is supported"

      connect do |redis|
        create_scenario
        AUIControl.organize2(@aui)

        @aui.save # there is still a bug, because save results in false!!
                  #.should==true

        n = MINT::AIO.first(:name => "Start")
                  #    n = @aui #
                  # 36.times {n=n.next}
                  #n.name.should=="Start"

        3.times {n=n.previous}
        n.name.should=="RecipeSelection_label"

        n = MINT::AIO.first(:name => "RecipeCalories")
        2.times {n=n.previous}
        n.name.should=="RecipeCuisine"

#     n = AIO.first(:name => "RecipeFinder")
#      3.times {n=n.previous} 
#     n.name.should=="RecipeFinder"
      end
    end

    it "should find the correct common aic for only one task in ETS" do
      connect do |redis|
        create_scenario
        AUIControl.find_common(["Start"]).should=="Start"
      end
    end

    it "should find the correct common aic for a given ETS" do
      connect do |redis|
        create_scenario
        AUIControl.find_common(["RecipeCuisine","RecipeCategory"]).should=="RecipeFilter"
        AUIControl.find_common(["Schweinebraten","RecipeSelection_description"]).should=="RecipeSelection"
        AUIControl.find_common(["Italian","Starter"]).should=="RecipeFilter"
        AUIControl.find_common(["RecipeFinder_label","RecipeFinder_description"]).should=="RecipeFinder"
        AUIControl.find_common(["Schweinebraten","RecipeCalories_choice","RecipeFinder_description"]).should=="RecipeFinder"
      end
    end

    it "should find the correct common AIContainer for a given ETS 2" do
      connect do |redis|
        create_scenario
        AUIControl.find_common(["RecipeCategory","Start", "FoundRecipes"]).should=="RecipeFinder"

        AUIControl.find_common(["RecipeCategory", "Start", "FoundRecipes", "RecipeCuisine", "RecipeCalories"]).should=="RecipeFinder"
      end
    end
  end
end