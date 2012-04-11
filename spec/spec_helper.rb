$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'rubygems'
require "rspec"
require "bundler/setup"
require 'statemachine'
require "cassowary"
require 'RMagick'
require 'drb/drb'
require 'redis'
require 'dm-core'
require 'dm-serializer'
require 'dm-types'
require 'eventmachine'
require 'em-hiredis'
require 'em-spec/rspec'

require 'support/connection_helper'
require 'support/statemachine_helper'
require 'stringio'

RSpec.configure do |config|
  config.include ConnectionHelper
  config.include StatemachineHelper
  config.include EventMachine::SpecHelper
end
