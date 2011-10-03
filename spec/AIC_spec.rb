require "spec_helper"

include MINT
describe 'AUI' do
  before :each do
    connection_options = { :adapter => "in_memory"}
    DataMapper.setup(:default, connection_options)
      #    DataMapper.setup(:default, { :adapter => "rinda",:local =>Rinda::TupleSpace.new})
    AIC.new(:name=>"a", :childs =>[
        AIO.new(:name => "e1"),
        AIO.new(:name => "e2"),
        AIO.new(:name => "e3")
    ]).save

    @a = AIC.first
  end

  describe 'AIC' do
    it 'should initialize with initiated' do
      @a.states.should ==[:initialized]
      @a.new_states.should == [:initialized]
    end

    it 'should transform to organizing state ' do
      @a.process_event(:organize).should ==[:organized]
      @a.states.should == [:organized]
      @a.new_states.should == [:organized]
    end

    it 'should support navigation to child' do
      aio = @a.childs.first
      aio.states=[:defocused]

      @a.states = [:focused]

      @a.process_event(:child)

      @a.states.should ==[:defocused]
      aio.states.should ==[:focused]
    end


    it 'should transform all children to presented if presented' do
      AUIControl.organize(@a,nil,0)
        # @a.process_event(:organize).should ==[:organized]
      @a.states.should == [:organized]
      @a.new_states.should == [:organized]
      @a.process_event(:present).should ==[:defocused]
      @a.childs.each do |c|
        c.states.should == [:defocused]
      end
    end

    it 'should transform all children to suspended if suspended' do
      @a.childs.each do |c|
        c.states = [:defocused]
      end
      @a.states = [:focused]

      @a.process_event(:suspend).should ==[:suspended]
      @a.childs.each do |c|
        c.states.should == [:suspended]
      end
    end



  end
end
