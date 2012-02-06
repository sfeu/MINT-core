$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'rubygems'
require "spec"
require "bundler/setup"
require 'statemachine'
require "cassowary"
require 'RMagick'
require 'drb/drb'
require 'redis'
require 'dm-core'
require 'dm-serializer'
require 'dm-types'

