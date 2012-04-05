require "spec_helper"

describe 'SingleChoiceElement' do
  before :each do
    connection_options = { :adapter => "in_memory"}
    DataMapper.setup(:default, connection_options)
    require "MINT-core"

        DataMapper.finalize
    @a = MINT::AISingleChoiceElement.create(:name => "test")
  end

  it 'should initialize with initiated' do
    @a.states.should == [:initialized]
  end

  it 'should transform to organizing state for present action' do
    @a.process_event(:organize).should == [:organized]
    @a.states.should == [:organized]
  end

  it 'should call back after event has been processed' do
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
      def sync_cio_to_listed
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
    @a.new_states.should == [:defocused, :unchosen, :p_t, :presenting, :selection_H]
    callback.called.should == false

    @a.process_event(:focus,callback).should == [:focused, :unchosen]
    @a.new_states.should == [:focused]
    callback.called.should == false

    @a.process_event(:next,callback).should == [:defocused, :unchosen]
    @a.new_states.should == [:defocused]
    callback.called.should == true
  end

  it 'should recover state after save and reload' do
    @a.process_event(:organize).should == [:organized]
    @a.save!
    b =  MINT::AIO.first(:name=>"test")
    b.states.should == [:organized]
    b.new_states.should == [:organized]
    b.process_event(:present).should == [:defocused, :unchosen]
    b.new_states.should == [:defocused, :unchosen, :p_t, :presenting, :selection_H]

  end

  it 'should recover state after save and reload from inside parallel state' do
    @a.process_event(:organize).should == [:organized]
    @a.process_event(:present).should == [:defocused, :unchosen]
    @a.process_event(:focus).should == [:focused, :unchosen]
    @a.save!
    b =  MINT::AIO.first(:name=>"test")
    b.states.should ==[:focused, :unchosen]
    b.process_event(:defocus).should == [:defocused, :unchosen]
    #b.process_event(:choose).should == [:presented, :choosing]
  end
  it 'should support for query-based selection' do
    @a.process_event(:organize).should == [:organized]
    @a.process_event(:present).should == [:defocused, :unchosen]
    @a.save!
    b =  MINT::AIO.first(:states=>/unchosen/)
    b.name.should == "test"
    c =  MINT::AIO.first(:states=>/defocused/)
    c.name.should == "test"
  end
  it 'should support for querying for superstates' do
    @a.process_event(:organize).should == [:organized]
    @a.process_event(:present).should == [:defocused, :unchosen]
    @a.save!
    puts @a.abstract_states
    b =  MINT::AIO.first(:abstract_states=>/presenting/)
    b.name.should == "test"
  end
  it "should save abstract states property upon initial element creation" do
    @a = MINT::AISingleChoiceElement.create(:name => "test")
    puts @a.abstract_states

  end
end
