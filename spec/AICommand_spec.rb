require "spec_helper"

require "em-spec/rspec"
require File.expand_path(File.join(File.dirname(__FILE__), 'shared/aio_shared'))

describe 'AUI' do

  before :each do
    Redis.connect.flushall
    @interactor_class =  MINT::AICommand
  end

  it_should_behave_like 'An AIO interactor'

  describe 'AICommand' do


  end

end
