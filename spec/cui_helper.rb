class CUIHelper
  def self.create_structure
    @up = MINT::CIO.create(:name => "up",:down =>"center")
    @down = MINT::CIO.create(:name => "down",:up=>"center")
    @left = MINT::CIO.create(:name => "left",:right=>"center")
    @right = MINT::CIO.create(:name => "right",:left=>"center")
    @center = MINT::CIO.create(:name => "center",:left=>"left",:right =>"right",:up =>"up", :down=>"down")

  end

  def self.create_structure_w_highlighted
    @up = MINT::CIO.create(:name => "up",:down =>"center",:states => [:displayed])
    @down = MINT::CIO.create(:name => "down",:up=>"center",:states => [:displayed])
    @left = MINT::CIO.create(:name => "left",:right=>"center",:states => [:displayed])
    @right = MINT::CIO.create(:name => "right",:left=>"center",:states => [:displayed])
    @center = MINT::CIO.create(:name => "center",:left=>"left",:right =>"right",:up =>"up", :down=>"down",:states => [:highlighted])
  end

  def self.set_highlighted
    @up.states=[:displayed]
    @down.states=[:displayed]
    @left.states=[:displayed]
    @right.states=[:displayed]
    @center.states=[:highlighted]
  end


  def self.scenario2
    center = create_structure
    @up.states=[:displayed]
    @down.states=[:displayed]
    @left.states=[:displayed]
    @right.states=[:displayed]
    @center.states=[:highlighted]

    @a_left = MINT::AIO.new(:name => "left",:states =>[:defocused])
    @a_left.save!

    @a_right = MINT::AIO.new(:name => "right",:states =>[:defocused])
    @a_right.save!
    @a_up = MINT::AIO.new(:name => "up",:states =>[:defocused])
    @a_up.save!
    @a_down = MINT::AIO.new(:name => "down",:states =>[:defocused])
    @a_down.save!
    @a_center = MINT::AIO.new(:name => "center",:states =>[:focused], :next =>"down")
    @a_center.save!
    center
  end

  def self.scenario3
    @center = MINT::CIO.create(:name => "center",:left=>"left",:states => [:highlighted])
    @left = MINT::CIO.create(:name => "left",:states => [:displayed])

    @a_center = MINT::AIO.create(:name => "center",:states =>[:focused], :next =>"left")
    @a_left = MINT::AIO.create(:name => "left",:states =>[:defocused])
  end

  def self.create_sync_mappings
    o1 = Observation.new(:element =>"Interactor.CIO", :states =>[:displaying], :result=> "cio")
    o2 = Observation.new(:eval => "AIO.get('aui',@cio.name)",:result=>"aio")
    o3 = Observation.new(:eval =>"not @aio.is_in(:presenting)")
    a = EventAction.new(:event => :present, :target => "aio")
    s = Sequence.new([o1,o2,o3],a)
    s.start

  end

  def self.layout_setup
    scenario2

    @up.states=[:initialized]
    @down.states=[:initialized]
    @left.states=[:initialized]
    @right.states=[:initialized]


    @a_left.states=[:organized]
    @a_right.states=[:organized]
    @a_up.states=[:organized]
    @a_down.states=[:organized]
  end


  def self.layout_scenario2(solver)
    MINT::AIContainer.create(:name=>"RecipeFinder_content",:states =>[:organized],:children=>"RecipeFilter")
    MINT::AIContainer.create(:name=>"RecipeFilter",:states =>[:organized],:children=>"RecipeFilter_description1|RecipeFilter_content")
    MINT::AIContainer.create(:name=>"RecipeFilter_description1",:states =>[:organized],:children=>"RecipeFilter_label|RecipeFilter_description")
    MINT::AIReference.create(:name=>"RecipeFilter_label",:label=>"Suchkriterien",:states =>[:organized])
    MINT::AIContext.new(:name=>"RecipeFilter_description",:states =>[:organized],
                        :text=>"In diesem Feld koennen Sie mit genauen Angaben zu Ihrem Gericht-Wunsch die Suche nach Ihrem Rezeptvorschlag eingrenzen.")
    MINT::AIContainer.create(:name=>"RecipeFilter_content",:states =>[:organized])


    @test = MINT::CIC.create( :name => "RecipeFinder_content", :rows => 1, :cols=> 1,:x=>0, :y=>0, :width =>800, :height => 600)

    @test.calculate_container(solver,10)
    @test
  end

end