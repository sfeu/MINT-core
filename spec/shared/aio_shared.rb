share_examples_for 'An AIO interactor' do
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

  it 'should publish initialize when created' do
    connect true  do |redis|
      test_state_flow redis,@interactor_class.create_channel_name+".test" ,%w(initialized) do
        @interactor_class.create(:name => "test")
      end
    end
  end

  it 'should change to initialized when created' do
    @a = @interactor_class.create(:name => "test")
    @a.states.should ==[:initialized]
    @a.new_states.should == [:initialized]
  end

  it 'should save with correct identifier' do
    @a = @interactor_class.create(:name => "test")
    redis = Redis.connect
    r = redis.hgetall("mint_interactors:"+@interactor_class.getModel+"test")
    r['name'].should == "test"
  end

  it 'should transform to organizing state for present action' do
    @a = @interactor_class.create(:name => "test")
    @a.process_event(:organize).should ==[:organized]
    @a.states.should == [:organized]
    @a.new_states.should == [:organized]
  end

  it 'should recover state after save and reload' do
    @a = @interactor_class.create(:name => "test")
    @a.process_event(:organize).should == [:organized]
    @a.save
    b =  @interactor_class.first(:mint_model =>@interactor_class.getModel, :name => "test")
    b.states.should == [:organized]
  end

  describe "and basic navigation" do
    it "should save prev/next links" do
      a = @interactor_class.create(:name => "test")
      b = @interactor_class.create(:name=>"next")
      a.next = "next"
      b.previous = "test"
      b.save.should == true
      a.save.should == true

      n = @interactor_class.first(:name=>"next")
      n.previous.should == a

      m = @interactor_class.first(:name=>"test")
      m.next.should == b
    end

    it 'should move focus to next element upon next' do
      a = @interactor_class.create(:name => "test",:next => "next")
      b = @interactor_class.create(:name=>"next",:previous => "test")

      a.process_event(:organize)
      b.process_event(:organize)

      a.process_event(:present)
      b.process_event(:present)

      a.process_event(:focus).should include :focused
      a.process_event(:next).should include :defocused

      b = @interactor_class.first(:name=>"next")
      b.states.should include :focused
      a.states.should include :defocused
    end

    it 'should move focus to previous element upon previous' do
      a = @interactor_class.create(:name => "test",:next => "next")
      b = @interactor_class.create(:name=>"next",:previous => "test")

      a.process_event(:organize)
      b.process_event(:organize)

      a.process_event(:present)
      b.process_event(:present)

      b.process_event(:focus).should include :focused
      b.process_event(:prev).should include :defocused

      a = @interactor_class.first(:name=>"test")
      a.states.should include :focused
      b.states.should include :defocused
    end

    it 'should not defocus on next if there is no next element' do
      a = @interactor_class.create(:name => "test")
      a.process_event(:organize)

      a.process_event(:present)

      a.process_event(:focus).should include :focused
      a.process_event(:next)
      a.states.should include :focused
    end

    it 'should not defocus on previous if there is no previous element' do
      a = @interactor_class.create(:name => "test")
      a.process_event(:organize)

      a.process_event(:present)

      a.process_event(:focus).should include :focused
      a.process_event(:prev).should include :focused
    end

    it 'should move focus to parent upon parent' do
      a = @interactor_class.create(:name => "test",:parent =>"parent")
      b =  MINT::AIContainer.create(:name=>"parent",:children =>["test"])

      a.process_event(:organize)
      b.process_event(:organize)

      a.process_event(:present)
      b.process_event(:present)

      a.process_event(:focus).should include :focused
      a.process_event(:parent).should include :defocused

      b = MINT::AIContainer.first(:name=>"parent")
      b.states.should include :focused
      a.states.should include :defocused

    end
  end
end