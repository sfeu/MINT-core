require "spec_helper"
require "em-spec/rspec"


describe 'Interactor' do
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

  it 'should initialize to initiated if no initial states have been set' do
    connect do |redis|
      MINT::Interactor.create(:name =>"test1")
      p = MINT::Interactor.all.first
      p.name.should == "test1"
      p.states.should == [:initialized]
      p.abstract_states.should == "Interactor|root"
    end
  end

  it 'should initialize to states set that have been set during creation' do
    connect do |redis|
      MINT::Interactor.create(:name =>"test2",:states=>[:finished])
      p = MINT::Interactor.all.first
      p.name.should == "test2"
      p.states.should == [:finished]
      p.abstract_states.should == "root"
    end
  end


end
