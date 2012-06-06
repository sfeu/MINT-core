$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module MINTCore
  VERSION = '1.0.1'
end

require 'rubygems'
require "bundler/setup"
require 'statemachine'
require "cassowary"
require 'RMagick'
require 'drb/drb'
require 'redis'
require 'dm-core'
require 'dm-serializer'
require 'dm-types'
require "MINT-scxml"
require "eventmachine"
require 'em-hiredis'

require "MINT-core/connector/redis_connector"
require "MINT-core/agent/agent"

require "MINT-core/model/interactor"
require "MINT-core/model/task"
require "MINT-core/agent/auicontrol"
require "MINT-core/agent/aui"
require "MINT-core/agent/cuicontrol"
require "MINT-core/agent/cuicontrol2"
require "MINT-core/agent/cui-gfx"
require "MINT-core/model/aui/model"
require "MINT-core/model/cui/gfx/model"

require "MINT-core/model/ir/pointer"
#require "MINT-core/model/device/button"
#require "MINT-core/model/device/wheel"
#require "MINT-core/model/device/joypad"
#require "MINT-core/model/device/mouse"
require "MINT-core/model/ir/mouse"

#require "MINT-core/model/body/gesture_button"
#require "MINT-core/model/body/handgesture"
require "MINT-core/model/body/head"

require "MINT-core/mapping/mapping"
require "MINT-core/mapping/sequential"
require "MINT-core/mapping/complementary_mapping"
require "MINT-core/mapping/observation/observation"
require "MINT-core/mapping/action/action"
require "MINT-core/mapping/action/backend_action"
require "MINT-core/mapping/action/event_action"
require "MINT-core/mapping/action/bind_action"

require "MINT-core/manager/mapping_parser"
require "MINT-core/manager/mapping_manager"
require "MINT-core/manager/mapping_server"

