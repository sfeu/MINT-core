require "spec_helper"

require "em-spec/rspec"


describe 'AUI' do
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


  describe 'AIO' do
    it 'should initialize with initiated' do
      connect do |redis|

        test_state_flow redis,"Interactor.AIO" ,%w(initialized)

        @a = MINT2::AIO.create(:name => "test")
        @a.states.should ==[:initialized]
        @a.new_states.should == [:initialized]
      end

    end

    it 'should save with correct identifier' do
      connect do |redis|

        @a = MINT2::AIO.create(:name => "test")
        redis = Redis.connect
        r = redis.hgetall("mint_elements:auitest")
        r['name'].should == "test"
      end

    end



    it 'should transform to organizing state for present action' do
      connect do |redis|
        @a = MINT2::AIO.create(:name => "test")
        @a.process_event(:organize).should ==[:organized]
        @a.states.should == [:organized]
        @a.new_states.should == [:organized]
      end
    end

    it 'should call back after event has been processed' do
      connect do |redis|
        class CallbackContext
          attr_accessor :called

          def initialize
            @called = false
          end
          def focus_next
            @called = true
          end
          def inform_parent_presenting
          end

          def sync_cio_to_displayed
          end
          def sync_cio_to_highlighted
          end
          def exists_next
            true
          end
          def exists_prev
            true
          end

        end

        callback = CallbackContext.new

        @a = MINT2::AIO.create(:name => "test")
        @a.process_event(:organize,callback).should == [:organized]
        callback.called.should == false

        @a.process_event(:present,callback).should == [:defocused]
        callback.called.should == false

        @a.process_event(:focus,callback).should == [:focused]
        callback.called.should == false

        @a.process_event(:next,callback).should == [:defocused]
        callback.called.should == true
      end
    end

    it 'should recover state after save and reload' do
      connect do |redis|
        DataMapper.finalize
        @a = MINT2::AIO.create(:name => "test")
        @a.process_event(:organize).should == [:organized]
        @a.save
        b =  MINT2::AIO.first(:mint_model =>"aui", :name => "test")
#        b =  MINT2::AIO.get("aui","test")
        b.states.should == [:organized]
        b.process_event(:present).should == [:defocused]
      end
    end

    it 'should store the state' do

      connect do |redis|
        a = MINT2::AIO.create(:name=>"RecipeSelection_label",:label=>"Rezeptdetails")
        a.states.should == [:initialized]
        a.process_event(:organize)
        a.states.should == [:organized]
        a.save!
        MINT2::AIO.get("aui","RecipeSelection_label").states.should == [:organized]
      end
    end


    #TODO Bug first sets states to array  not sure ahy

    #    it "should process after load" do
    #      t = MINT::AIO.create(:name => "p")
    #
    #      b = MINT::AIO.first(:name => "p")
    #     # b.states.should == [:initialized]
    #      b.process_event(:organized)
    #
    #    end


    it "should save prev/next links" do
      pending "navigation currently not supported"
      connect do |redis|
        @a = MINT2::AIO.create(:name => "test")
        b =  MINT2::AIO.create(:name=>"next")
        # @a.next = b
        b.previous =@a
        b.save.should == true
        @a.save.should == true

        n = MINT2::AIO.first(:name=>"next")
        n.previous.should == @a
      end
    end

    it 'should focus to next element' do
      pending "navigation currently not supported"
      connect do |redis|
        @a = MINT2::AIO.create(:name => "test")
        b =  MINT2::AIO.create(:name=>"next")
        @a.next = b
        b.previous =@a

        @a.process_event(:organize)
        b.process_event(:organize)

        @a.process_event(:present)
        b.process_event(:present)

        @a.process_event(:focus).should == [:focused]

        @a.process_event(:next).should == [:defocused]
        b.states.should ==[:focused]
        @a.states.should ==[:defocused]
      end
    end

    it 'should not defocus on next if there is no next element' do
      pending "navigation currently not supported"
      connect do |redis|
        @a = MINT2::AIO.create(:name => "test")
        @a.states=[:focused]
        @a.process_event(:next)
        @a.states.should == [:focused]
      end
    end

    it 'should not defocus on prev if there is no previous element' do
      pending "navigation currently not supported"
      connect do |redis|
        @a = MINT2::AIO.create(:name => "test")
        @a.states=[:focused]
        @a.process_event(:prev).should ==[:focused]
      end
    end

    it 'should handle previous' do
      pending "navigation currently not supported"
      connect do |redis|
        @a = MINT2::AIO.create(:name => "test")
        @a.states=[:defocused]
        b =  MINT2::AIO.new(:name=>"test", :previous =>@a)
        b.states= [:focused]
        b.process_event(:prev)

        @a.states.should ==[:focused]
        b.states.should ==[:defocused]
      end
    end

    it 'should handle parent' do
      @a.states=[:focused]
      b =  MINT::AIC.new(:name=>"parent",:childs =>[@a])
      b.states = [:defocused]
      @a.process_event(:parent)
      
      @a.states.should ==[:defocused]
      b.states.should ==[:focused]
    end

    it 'should serialize to JSON' do
      connect do |redis|
        @a = MINT2::AIO.create(:name => "test")
        require 'dm-serializer'
        @a.states=[:focused]

        puts @a.to_json                      # => { "id": 1, "name": "Berta" }
      end
    end

  end

end
