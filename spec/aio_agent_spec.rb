require "spec"
require "spec_helper"

describe 'AUI-Agent' do
  before :each do
connection_options = { :adapter => "redis"}
 DataMapper.setup(:default, connection_options)
#  DataMapper.setup(:default, { :adapter => "rinda", :host =>"localhost",:port=>4000})
    # ,:local =>Rinda::TupleSpace.new})
   # DataMapper::Logger.new("data.log", :debug)
    @aui = AIC.new(:name=>"RecipeFinder", 
        :childs =>[
                   AIReference.new(:name=>"RecipeFinder_label",:label=>"Willkommen"),
                   AIOUTContext.new(:name=>"RecipeFinder_description",:text=>"Willkommen beim 4 Sterne Koch Assistenten."),
                   AIC.new(:name=>"RecipeFilter",
                           :childs => [
                                       AIReference.new(:name=>"RecipeFilter_label",:label=>"Suchkriterien"),
                                       AIOUTContext.new(:name=>"RecipeFilter_description",:text=>"In diesem Feld können Sie mit genauen Angaben zu Ihrem Gericht-Wunsch die Suche nach Ihrem Rezeptvorschlag eingrenzen."),
                                       AIC.new(:name=>"RecipeCuisine", 
                                               :childs=>[
                                                         AIReference.new(:name=>"RecipeCuisine_label",:label=>"Nationale Küche"),
                                                         AIOUTContext.new(:name=>"RecipeCuisine_description",:text=>"Welche nationale Küche wählen Sie? "),
                                                         AIMultiChoice.new(:name=>"RecipeCuisine_choice", 
                                                                           :childs =>[
                                                                                      AIINChoose.new(:name => "French", :label =>"Französisch"),
                                                                                      AIINChoose.new(:name => "German",:label =>"Deutsch"),
                                                                                      AIINChoose.new(:name => "Italian",:label =>"Italienisch"),
                                                                                      AIINChoose.new(:name => "Chinese",:label =>"Chinesisch")
                                                                                     ] 
                                                                          )
                                                        ]),
                                       AIC.new(:name=>"RecipeCategory",
                                               :childs=>[
                                                         AIReference.new(:name=>"RecipeCategory_label",:label=>"Menǘart "),
                                                         AIOUTContext.new(:name=>"RecipeCategory_description",:text=>" Welche Menǘart möchten Sie kochen? "),
                                                         AIMultiChoice.new(:name=>"RecipeCategory_choice", 
                                                                           :childs =>[
                                                                                      AIINChoose.new(:name => "Main", :label =>"Hauptgericht"),
                                                                                      AIINChoose.new(:name => "Pastry",:label =>"Gebäck"),
                                                                                      AIINChoose.new(:name => "Dessert",:label =>"Nachtisch"),
                                                                                      AIINChoose.new(:name => "Starter",:label =>"Vorspeise")
                                                                                     ] 
                                                                          )
                                                        ]),
                                       AIC.new(:name=>"RecipeCalories",
                                               :childs=>[
                                                         AIReference.new(:name=>"RecipeCalories_label",:label=>"gesundheitsbewusst "),
                                                         AIOUTContext.new(:name=>"RecipeCalories_description",:text=>" Wollen Sie gesundheitsbewusst kochen? "),
                                                         AISingleChoice.new(:name=>"RecipeCalories_choice", 
                                                                           :childs =>[
                                                                                      AIINChoose.new(:name => "Diet", :label =>"Hauptgericht"),
                                                                                      AIINChoose.new(:name => "Low fat",:label =>"Gebäck"),
                                                                                      AIINChoose.new(:name => "Not Relevant",:label =>"Nachtisch"),
                                                                                     ] 
                                                                          )
                                                        ]),
                                       ]),
                   AIC.new(:name =>"RecipeSelection",
                           :childs => [
                                       AIReference.new(:name=>"RecipeSelection_label",:label=>"Rezeptdetails"),
                                       AIOUTContext.new(:name=>"RecipeSelection_description",:text=>"Hier werden Ihre Rezeptvorschläge mit den Details angezeigt und Sie können bestimmen, für wieviele Personen das Rezept berechnet werden soll."),
                                       AISingleChoice.new(:name=>"FoundRecipes", 
                                                                           :childs =>[
                                                                                      AIINChoose.new(:name => "Schweinebraten", :label =>"Schweinebraten"),
                                                                                      AIINChoose.new(:name => "Lamkotletts",:label =>"Lammkotletts"),
                                                                                      AIINChoose.new(:name => "Spagetti",:label =>"Spagetti"),
                                                                                     ] 
                                                                          ),
                                       AICommand.new(:name=>"Start",:label=>"Kochassistent starten",:description=>"Hier können Sie den Kochassistenten starten.")
                                       ])
                  ])
      @aui.save!

  end
  
  describe 'organizing' do
 
    it 'should save correctly' do
      class P <Interactor
 
#        belongs_to :c
        belongs_to  :parent, 'C',
        :parent_key => [ :id ],       # in the remote model (Blog)
        :child_key  => [ :c_id ],  # local to this model (Post)
        :required   => true 
        
        has 1, :next, P
        has 1, :previous, P
      end
      
     class C < P
       has n, :childs, 'P',
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
      aic = AIC.new(:name =>"AIC", :childs=>[AIO.new(:name=>"AIO")])
      aic.save!
      
      AIO.first(:name=>"AIO").parent.name.should == "AIC"
    end
    
    it "should organize parental relations correctly 2" do
      AIC.new(:name=>"RecipeFinder", 
        :childs =>[
                   AIReference.new(:name=>"RecipeFinder_label",:label=>"Willkommen")]).save!
       
      AIO.first(:name=>"RecipeFinder_label").parent.name.should == "RecipeFinder"
    end
 
    it "should organize parental relations correctly 3" do
       AIO.first(:name=>"RecipeFinder_label").parent.name.should == "RecipeFinder"
      end
    
    it 'should organize with parental relationships 4' do
      AIINChoose.first(:name => "Main").parent.name.should ==  "RecipeCategory_choice"
    end
    
    it 'should support next navigation' do
         pending("get the organize function working")
      AUIControl.organize(@aui)
       @aui.save!#.should==true      
      @aui.next.name.should=="RecipeFinder_label"
      @aui.next.next.next.next.name.should=="RecipeFilter_label"

      
      n = AIO.first(:name => "RecipeFinder")
      10.times {n=n.next} 
      n.name.should=="French"
      12.times {n=n.next} 
      n.name.should=="RecipeCalories"
      14.times {n=n.next} 
      n.name.should=="Start"
    end
    
    it "should support previous navigation" do
      pending("inconsistency in the database")
      AUIControl.organize(@aui)
      
       @aui.save! # there is still a bug, because save results in false!!
        #.should==true

      n = AIO.first(:name => "Start")
   #    n = @aui # 
     # 36.times {n=n.next} 
      #n.name.should=="Start"
      
      10.times {n=n.previous} 
      n.name.should=="Diet"
      4.times {n=n.previous} 
      n.name.should=="RecipeCalories"
      22.times {n=n.previous} 
      n.name.should=="RecipeFinder"
    end

it 'should support next navigation in organize 2' do
      pending("get the organize2 function working")
      AUIControl.organize2(@aui)
       # @aui.save#.should==true      
      # @aui.next.name.should=="RecipeFinder"
      # @aui.next.next.next.next.name.should=="RecipeFinder"

      
      n = AIO.first(:name => "RecipeFinder_label")
      3.times {n=n.next} 
      n.name.should=="RecipeSelection"

      n = AIO.first(:name => "RecipeCalories_label")
      2.times {n=n.next} 
      n.name.should=="RecipeCalories_choice"

#     n = AIO.first(:name => "Start")
#      7.times {n=n.next} 
#      n.name.should=="FoundRecipes"
    end
    
    it "should support previous navigation in organize 2" do
      
      AUIControl.organize2(@aui)
      
       @aui.save # there is still a bug, because save results in false!!
        #.should==true

      n = AIO.first(:name => "Start")
   #    n = @aui # 
     # 36.times {n=n.next} 
      #n.name.should=="Start"
      
      3.times {n=n.previous} 
      n.name.should=="RecipeSelection_label"
      
     n = AIO.first(:name => "RecipeCalories")
     2.times {n=n.previous} 
      n.name.should=="RecipeCuisine"

#     n = AIO.first(:name => "RecipeFinder")
#      3.times {n=n.previous} 
 #     n.name.should=="RecipeFinder"
    end
    
    it "should find the correct common aic for only one task in ETS" do
      AUIControl.find_common(["Start"]).should=="Start"
    end
    
    it "should find the correct common aic for a given ETS" do
      AUIControl.find_common(["RecipeCuisine","RecipeCategory"]).should=="RecipeFilter"
      AUIControl.find_common(["Schweinebraten","RecipeSelection_description"]).should=="RecipeSelection"
      AUIControl.find_common(["Italian","Starter"]).should=="RecipeFilter"
      AUIControl.find_common(["RecipeFinder_label","RecipeFinder_description"]).should=="RecipeFinder"
      AUIControl.find_common(["Schweinebraten","RecipeCalories_choice","RecipeFinder_description"]).should=="RecipeFinder"
    end
    
    it "should find the correct common AIC for a given ETS 2" do
       AUIControl.find_common(["RecipeCategory","Start", "FoundRecipes"]).should=="RecipeFinder"
      AUIControl.find_common(["RecipeCategory", "Start", "FoundRecipes", "RecipeCuisine", "RecipeCalories"]).should=="RecipeFinder"
    end
  end
end
