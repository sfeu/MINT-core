require "spec_helper"

require "em-spec/rspec"
require File.expand_path(File.join(File.dirname(__FILE__), 'shared/aio_shared'))

describe 'AUI' do

  before :each do
    Redis.connect.flushall
    @interactor_class =  MINT::AIO
  end

  it_should_behave_like 'An AIO interactor'

  describe 'AIO' do

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
