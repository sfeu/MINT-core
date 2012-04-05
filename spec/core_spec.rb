require "spec_helper"



describe 'Interactor' do
  before :each do
    connection_options = { :adapter => "in_memory"}
    DataMapper.setup(:default, connection_options)
  end

  it 'should initialize to initiated if no initial states have been set' do
    Element.create(:name =>"test1")
    p = Element.all.first
    p.name.should == "test1"
    p.states.should == [:initialized]
    p.abstract_states.should == "root|initialized"
  end

  it 'should initialize to states set have been been set during creation' do
    Element.create(:name =>"test2",:states=>[:finished])
    p = Element.all.first
    p.name.should == "test2"
    p.states.should == [:finished]
    p.abstract_states.should == "root|finished"
  end


end
