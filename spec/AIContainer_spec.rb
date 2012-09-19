require "spec_helper"
require "em-spec/rspec"

describe 'AUI' do
  include EventMachine::SpecHelper

  before :all do
    class ::Helper
      def self.create_structure
        MINT::AIContainer.create(:name=>"a", :children =>"e1|e2|e3")
        MINT::AIO.create(:name => "e1", :parent=>"a")
        MINT::AIO.create(:name => "e2", :parent=>"a")
        MINT::AIO.create(:name => "e3", :parent=>"a")
        MINT::AIContainer.first

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


  describe 'AIContainer' do
    it 'should initialize with initiated' do
      connect do |redis|
        @a = Helper.create_structure

        @a.states.should ==[:initialized]
        @a.new_states.should == [:initialized]
      end
    end

    it 'should transform to organizing state ' do
      connect do |redis|
        @a = Helper.create_structure
        @a.process_event(:organize).should ==[:organized]
        @a.states.should == [:organized]
        @a.new_states.should == [:organized]
      end
    end

    it 'should support parent navigation' do
      connect do |redis|
        @a = Helper.create_structure
        e = MINT::AIO.first(:name => "e1")
        p = e.parent
        p.should == @a
      end
    end

    it 'should support navigation to child' do

      connect do |redis|
        @a = Helper.create_structure

        aio = @a.children.first
        aio.states=[:defocused]

        @a.states = [:focused]

        @a.process_event(:child)

        @a.states.should ==[:defocused]
        e = MINT::AIO.first(:name => "e1")
        e.states.should ==[:focused]
      end
    end


    it 'should transform all children to presented if presented' do
      connect do |redis|
        @a = Helper.create_structure
        AUIControl.organize(@a,nil,0)
        # @a.process_event(:organize).should ==[:organized]
        @a.states.should == [:organized]
        @a.new_states.should == [:organized]
        @a.process_event(:present).should ==[:defocused]
        @a.children.each do |c|
          c.states.should == [:defocused]
        end
      end
    end

    it 'should transform all children to suspended if suspended' do
      connect do |redis|
        @a = Helper.create_structure
        @a.children.each do |c|
          c.states = [:defocused]
        end
        @a.states = [:focused]

        @a.process_event(:suspend).should ==[:suspended]
        @a.children.each do |c|
          c.states.should == [:suspended]
        end
      end
    end

    it 'should transform all children to suspended if AUIControl.suspend_all is called' do
          connect do |redis|
            @b = MINT::AIContainer.create(:name=>"b", :children =>"a")
            @b.states = [:defocused]

            @a = Helper.create_structure
            @a.parent = "b"

            @a.children.each do |c|
              c.states = [:defocused]
              c.save
            end
            @a.states = [:focused]

            #@b.process_event(:suspend).should ==[:suspended]
            AUIControl.suspend_all

            @a = MINT::AIContainer.first(:name=>"a")
            @a.states.should == [:suspended]
            @a.children.each do |c|
              c.states.should == [:suspended]
            end
          end
        end




    it 'AIO should handle parent' do
      connect do |redis|

        MINT::AIContainer.create(:name=>"parent", :states => [:defocused],:children =>"a1")
        MINT::AIContainer.create(:name=>"a1", :states => [:focused],:children =>"ee1|ee2|ee3",:parent=>"parent")
        MINT::AIO.create(:name => "ee1",:states => [:defocused],:parent=>"a1")
        MINT::AIO.create(:name => "ee2",:states => [:defocused],:parent=>"a1")
        MINT::AIO.create(:name => "ee3",:states => [:defocused],:parent=>"a1")
        @a = MINT::AIContainer.first(:name => "a1")
        b = MINT::AIContainer.first(:name => "parent")


        @a.states.should == [:focused]
        #b =  MINT2::AIContainer.create(:name=>"parent",:children =>[@a])
        b.states.should == [:defocused]
        @a.process_event(:parent)

        @a.states.should ==[:defocused]

        b = MINT::AIContainer.first(:name => "parent")
        b.states.should ==[:focused]
      end
    end

  end
end
