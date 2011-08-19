require "spec_helper"

describe 'AUI' do
  before :each do
    connection_options = { :adapter => "in_memory"}
     DataMapper.setup(:default, connection_options)
 #    DataMapper.setup(:default, { :adapter => "rinda",:local =>Rinda::TupleSpace.new})
    @a = MINT::AIO.create(:name => "test")

  end
  
  describe 'AIO' do
    it 'should initialize with initiated' do
      @a.states.should ==[:initialized]
      @a.new_states.should == [:initialized]
    end

    it 'should transform to organizing state for present action' do
      @a.process_event(:organize).should ==[:organized]
      @a.states.should == [:organized]
      @a.new_states.should == [:organized]
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

      @a.process_event(:organize,callback).should == [:organized]
      callback.called.should == false
      
      @a.process_event(:present,callback).should == [:defocused]
      callback.called.should == false
      
      @a.process_event(:focus,callback).should == [:focused]
      callback.called.should == false

      @a.process_event(:next,callback).should == [:defocused]
      callback.called.should == true
    end
    
    it 'should recover state after save and reload' do
      @a.process_event(:organize).should == [:organized]
      @a.save!
      b =  MINT::AIO.first(:name=>"test")
      b.states.should == [:organized]
      b.process_event(:present).should == [:defocused]
    end

    it 'should store the state' do
      a = MINT::AIINReference.create(:name=>"RecipeSelection_label",:label=>"Rezeptdetails")
      a.states.should == [:initialized]
      a.process_event(:organize)
      a.states.should == [:organized]
      a.save!
      MINT::AIINReference.first(:name=>"RecipeSelection_label").states.should == [:organized]
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


    it 'should focus to next element' do
      b =  MINT::AIO.create(:name=>"next")
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
    
    it 'should not defocus on next if there is no next element' do
      
      @a.states=[:focused]
      @a.process_event(:next)
      @a.states.should == [:focused]
    end
    
    it 'should not defocus on prev if there is no previous element' do
      @a.states=[:focused]
      @a.process_event(:prev).should ==[:focused]
    end
    
    it 'should handle previous' do
      @a.states=[:defocused]
      b =  MINT::AIO.new(:name=>"test", :previous =>@a)
      b.states= [:focused]
      b.process_event(:prev)
      
      @a.states.should ==[:focused]
      b.states.should ==[:defocused]
    end
    
    it 'should handle parent' do
      @a.states=[:focused]
      b =  MINT::AIC.new(:name=>"parent",:childs =>[@a])
      b.states = [:defocused]
      @a.process_event(:parent)
      
      @a.states.should ==[:defocused]
      b.states.should ==[:focused]
    end
  end
  describe 'AIC' do
    it 'should support navigation to child' do
      aio = MINT::AIO.new(:name=>"child")
      aio.states=[:defocused]
      aic =  MINT::AIC.new(:name=>"parent",
                           :childs =>[ aio ])
      aic.states = [:focused]

      aic.process_event(:child)
     
      aic.states.should ==[:defocused]
      aio.states.should ==[:focused]
    end
  end
end
