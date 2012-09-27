require "spec_helper"

describe 'SingleChoiceElement' do

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

  it 'should initialize with initiated' do
    connect do |redis|
      @a = MINT::AISingleChoiceElement.create(:name => "test")
      @a.states.should == [:initialized]
    end
  end

  it 'should transform to organizing state for present action' do
    connect do |redis|
      @a = MINT::AISingleChoiceElement.create(:name => "test")
      @a.process_event(:organize).should == [:organized]
      @a.states.should == [:organized]
    end
  end

  it 'should call back after event has been processed' do
    connect do |redis|
      @a = MINT::AISingleChoiceElement.create(:name => "test")
      class CallbackContext
        attr_accessor :called

        def initialize
          @called = false
        end
        def focus_next
          @called = true
        end
        def sync_cio_to_displayed
        end
        def sync_cio_to_highlighted
        end
        def sync_cio_to_unchosen
        end
        def exists_next
          true
        end
        def exists_prev
          true
        end
      end

      callback = CallbackContext.new


      @a.process_event(:organize,callback).should == [:organized]
      callback.called.should == false

      @a.process_event(:present,callback).should == [:defocused, :unchosen]
      @a.states.should == [:defocused, :unchosen]
      @a.new_states.should == [:defocused, :unchosen, :p, :presenting, :choice, :c]
      callback.called.should == false

      @a.process_event(:focus,callback).should == [:focused, :unchosen]
      @a.new_states.should == [:focused]
      callback.called.should == false

      @a.process_event(:next,callback).should == [:defocused, :unchosen]
      @a.new_states.should == [:defocused]
      callback.called.should == true
    end
  end

  it 'should recover state after save and reload' do
    connect do |redis|
      @a = MINT::AISingleChoiceElement.create(:name => "test")
      @a.process_event(:organize).should == [:organized]
      @a.save!
      b =  MINT::AIO.first(:name=>"test")
      b.states.should == [:organized]
      b.new_states.should == [:organized]
      b.process_event(:present).should == [:defocused, :unchosen]
      b.new_states.should == [:defocused, :unchosen, :p, :presenting, :choice, :c]
    end
  end

  it 'should recover state after save and reload from inside parallel state' do
    connect do |redis|
      @a = MINT::AISingleChoiceElement.create(:name => "test")
      @a.process_event(:organize).should == [:organized]
      @a.process_event(:present).should == [:defocused, :unchosen]
      @a.process_event(:focus).should == [:focused, :unchosen]
      @a.save!
      b =  MINT::AIO.first(:name=>"test")
      b.states.should ==[:focused, :unchosen]
      b.process_event(:defocus).should == [:defocused, :unchosen]
      #b.process_event(:choose).should == [:presented, :choosing]
    end
  end

  it 'should support for query-based selection' do
    connect do |redis|
      @a = MINT::AISingleChoiceElement.create(:name => "test")
      @a.process_event(:organize).should == [:organized]
      @a.process_event(:present).should == [:defocused, :unchosen]
      @a.save!
      b =  MINT::AIO.first(:states=>/unchosen/)
      b.name.should == "test"
      c =  MINT::AIO.first(:states=>/defocused/)
      c.name.should == "test"
    end
  end

  it 'should support for querying for superstates' do
    connect do |redis|
      @a = MINT::AISingleChoiceElement.create(:name => "test")
      @a.process_event(:organize).should == [:organized]
      @a.process_event(:present).should == [:defocused, :unchosen]
      @a.save!
      puts @a.abstract_states
      b =  MINT::AIO.first(:abstract_states=>/presenting/)
      b.name.should == "test"
    end
  end

  it "should save abstract states property upon initial element creation" do
    connect do |redis|
      @a = MINT::AISingleChoiceElement.create(:name => "test")
      @a.abstract_states.should == "AISingleChoiceElement|root"
    end
  end

  it "should retrieve the correct abstract states after entering parallel states" do
    connect do |redis|
      @a = MINT::AISingleChoiceElement.create(:name => "test")
      @a.process_event(:organize).should == [:organized]
      @a.process_event(:present).should == [:defocused, :unchosen]
      @a.abstract_states.should == "AISingleChoiceElement|root|p|presenting|choice|c"
    end
  end

  it "should retrieve the correct abstract states after leaving parallel states" do
    connect do |redis|
      @a = MINT::AISingleChoiceElement.create(:name => "test")
      @a.process_event(:organize).should == [:organized]
      @a.process_event(:present).should == [:defocused, :unchosen]
      @a.process_event(:suspend).should == [:suspended]
      @a.abstract_states.should == "AISingleChoiceElement|root"
    end
  end

  it "should remove itself from parent choice if it enters dragging state (case: choice with just one element)" do
    connect do |redis|
      @a = MINT::AISingleChoiceElement.create(:name => "test",:parent=>"choice",:states=> [:focused, :chosen])
      @c = MINT::AISingleChoice.create(:name => "choice",:children=>"test",:states=>[:defocused,:listing])

      @a.process_event(:drag).should == [:focused,:dragging]

      MINT::AISingleChoiceElement.first.parent.should == nil
      MINT::AISingleChoice.first.children.to_a.empty?.should ==true

    end
  end

  it "should remove itself from parent choice if it enters dragging state (case: choice with several elements)" do
    connect do |redis|
      MINT::AISingleChoiceElement.create(:name => "A",:parent=>"choice",:states=> [:focused, :chosen])
      @a = MINT::AISingleChoiceElement.create(:name => "B",:parent=>"choice",:states=> [:focused, :chosen])
      MINT::AISingleChoiceElement.create(:name => "C",:parent=>"choice",:states=> [:focused, :chosen])

      @c = MINT::AISingleChoice.create(:name => "choice",:children=>"A|B|C",:states=>[:defocused,:listing])

      @a.process_event(:drag).should == [:focused,:dragging]

      MINT::AISingleChoiceElement.get("aui","B").parent.should == nil
      MINT::AISingleChoice.first.children.length.should == 2

    end
  end


end
