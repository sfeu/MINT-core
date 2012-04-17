require "spec_helper"

require "em-spec/rspec"


describe 'AUI' do
  include EventMachine::SpecHelper

  before :all do
    connection_options = { :adapter => "redis"}
    DataMapper.setup(:default, connection_options)


    connect do |redis|
      require "MINT-core"
      require "support/redis_connector_monkey_patch"  # TODO dirty patch for a bug that i have not found :(
      DataMapper.finalize
      DataMapper::Model.raise_on_save_failure = true
    end
  end


  describe 'AIO' do
    it 'should initialize with initiated' do
      connect do |redis|

        test_state_flow redis,"Interactor.AIO" ,%w(initialized)

        @a = MINT::AIO.create(:name => "test")
        @a.states.should ==[:initialized]
        @a.new_states.should == [:initialized]
      end

    end

    it 'should save with correct identifier' do
      connect do |redis|

        @a = MINT::AIO.create(:name => "test")
        redis = Redis.connect
        r = redis.hgetall("mint_interactors:auitest")
        r['name'].should == "test"
      end

    end



    it 'should transform to organizing state for present action' do
      connect do |redis|
        @a = MINT::AIO.create(:name => "test")
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

        @a = MINT::AIO.create(:name => "test")
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
        #    DataMapper.finalize
        @a = MINT::AIO.create(:name => "test")
        @a.process_event(:organize).should == [:organized]
        @a.save
        b =  MINT::AIO.first(:mint_model =>"aui", :name => "test")
#        b =  MINT2::AIO.get("aui","test")
        b.states.should == [:organized]
        b.process_event(:present)# .should == [:defocused]
      end
    end

    it 'should store the state' do

      connect do |redis|
        a = MINT::AIO.create(:name=>"RecipeSelection_label",:label=>"Rezeptdetails")
        a.states.should == [:initialized]
        a.process_event(:organize)
        a.states.should == [:organized]
        a.save!
        MINT::AIO.get("aui","RecipeSelection_label").states.should == [:organized]
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
      connect do |redis|
        @a = MINT::AIO.create(:name => "test")
        b =  MINT::AIO.create(:name=>"next")
        @a.next = "next"
        b.previous = "test"
        b.save.should == true
        @a.save.should == true

        n = MINT::AIO.first(:name=>"next")
        n.previous.should == @a
      end
    end

    it 'should focus to next element' do
      #pending "navigation currently not supported"
      connect do |redis|
        @a = MINT::AIO.create(:name => "test")
        b =  MINT::AIO.create(:name=>"next")
        @a.next = "next"
        b.previous = "test"

        @a.process_event(:organize)
        b.process_event(:organize)

        @a.process_event(:present)
        b.process_event(:present)

        @a.process_event(:focus).should == [:focused]

        @a.process_event(:next).should == [:defocused]
        b = MINT::AIO.first(:name=>"next")
        b.states.should ==[:focused]
        @a.states.should ==[:defocused]
      end
    end

    it 'should not defocus on next if there is no next element' do
      connect do |redis|
        @a = MINT::AIO.create(:name => "test")
        @a.states=[:focused]
        @a.process_event(:next)
        @a.states.should == [:focused]
      end
    end

    it 'should not defocus on prev if there is no previous element' do
      connect do |redis|
        @a = MINT::AIO.create(:name => "test")
        @a.states=[:focused]
        @a.process_event(:prev).should ==[:focused]
      end
    end

    it 'should handle previous' do
      connect do |redis|
        @a = MINT::AIO.create(:name => "test")
        @a.states=[:defocused]
        b =  MINT::AIO.new(:name=>"next", :previous =>"test")
        b.states= [:focused]
        b.process_event(:prev)

        c = MINT::AIO.first(:name=>"test")
        c.states.should ==[:focused]
        b.states.should ==[:defocused]
      end
    end

    it 'should handle parent' do
      connect do |redis|
      @a = MINT::AIO.create(:name => "test",:parent =>"parent",:states=>[:focused])
      b =  MINT::AIContainer.create(:name=>"parent",:children =>["test"],:states => [:defocused])
      @a.process_event(:parent)

      @a.states.should ==[:defocused]
      b = MINT::AIContainer.first(:name=>"parent")

      b.states.should ==[:focused]
      end
    end

    it 'should serialize to JSON' do
      connect do |redis|
        @a = MINT::AIO.create(:name => "test")
        require 'dm-serializer'
        @a.states=[:focused]

        puts @a.to_json                      # => { "id": 1, "name": "Berta" }
      end
    end

  end

end
