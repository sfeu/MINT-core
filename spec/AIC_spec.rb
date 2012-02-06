require "spec_helper"

describe 'AUI' do
  before :each do
    connection_options = { :adapter => "redis"}
    DataMapper.setup(:default, connection_options)
      #    DataMapper.setup(:default, { :adapter => "rinda",:local =>Rinda::TupleSpace.new})
     require "MINT-core"
    redis = Redis.connect
    redis.flushdb


    DataMapper.finalize

    MINT2::AIC.new(:name=>"a", :children =>[
            MINT2::AIO.new(:name => "e1"),
            MINT2::AIO.new(:name => "e2"),
            MINT2::AIO.new(:name => "e3")
    ]).save
    @a = MINT2::AIC.first
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
      aio = @a.children.first
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


    it 'AIO should handle parent' do
      @a.states=[:focused]
      b =  MINT2::AIC.new(:name=>"parent",:childs =>[@a])
      b.states = [:defocused]
      @a.process_event(:parent)

      @a.states.should ==[:defocused]
      b.states.should ==[:focused]
    end


  end
end
