$:.unshift(File.dirname(__FILE__)) unless
    $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require "bundler/setup"
require "eventmachine"
require 'dm-core'
require 'redis'
require 'hiredis'
require 'fiber'

#require "one_hand_nav_flexible_ticker"
#require "one_hand_nav_just_ticker"


class StatefulProtocol < EventMachine::Connection
  include EM::Protocols::LineText2
  attr_accessor :hand_gesture
  attr_accessor :speed

  def initialize
    super()
    @zoom_level=0

    #tracks distance for one handed interaction
    @distance_level = 0

    # calibrates the distance when previous or next gesture is issued
    @calibrated_distance = 0
    # threshold for distance tracking
    @distance_threshold = 1
    #    @factor = 25 was working well for zooming gesture
    @factor = 150

    # the timeout value range and stepping
    @min_command_timeout = 0.4
    @max_command_timeout = 1.6
    @command_timeout_step = 0.1
    @speed =  MINT::Speed.first_or_create(:name => 'speed')
    @drop_counter=0
  end

  def receive_line(data)
    begin
      case data
        when /ZOOM-\d+/
          d = /ZOOM-(\d+)/.match(data)[1].to_i
          if (@zoom_level == 0)
            @zoom_level = d
            return
          end
          if (d>(@zoom_level+@factor))
            @zoom_level = d
            @hand_gesture.process_event(:widen,d)
          elsif (d<(@zoom_level-@factor))
            @hand_gesture.process_event(:narrow,d)
            @zoom_level = d
          end
        when /AREA-\d+/
          if @drop_counter >0
            @drop_counter =0
            return
          end
          @drop_counter +=1

          r = /AREA-(\d+)/.match(data)[1].to_i
          @distance_level = Math.sqrt(r).to_i # transformation to a linear function
          puts "received #{@distance_level} calibration: #{@calibrated_distance}"
          if @calibrated_distance == 0 # the first area after a next of prev gesture is uesed for calibration
            return
          end
          if (@calibrated_distance-@distance_level)>(@distance_threshold)
            p "FARER"
            # hand is moved away from screen


            #          if (@hand_gesture.command_timeout < @max_command_timeout)
            #           @hand_gesture.command_timeout =  @hand_gesture.command_timeout + @command_timeout_step
            #          puts "AWAAAAAAYYYYY #{@hand_gesture.command_timeout} "
            #         @speed.update(:value=>@hand_gesture.command_timeout*10)

            #        @speed.process_event("slower")
            #@calibrated_distance= @distance_level
            #else
            @calibrated_distance= @distance_level
            @hand_gesture.process_event(:farer)
            #  puts "away limit"
            # end
            return
          end
          if (@distance_level-@calibrated_distance)>(@distance_threshold)
            p "CLOOOOSER"
#          puts "calibration: #{@calibrated_distance}"
# hand is moved closer to screen
#         if (@hand_gesture.command_timeout > @min_command_timeout)

#          @hand_gesture.command_timeout =  @hand_gesture.command_timeout - @command_timeout_step
#         puts "CLOOOOOOSER: #{@hand_gesture.command_timeout} "
#        @speed.update(:value=>@hand_gesture.command_timeout*10)
#       @speed.process_event("faster")
#@calibrated_distance= @distance_level
#    else
            @calibrated_distance= @distance_level
            @hand_gesture.process_event(:closer)
#    puts "closer limit"
#   end
            return
          end
        when /PREV/
          @hand_gesture.process_event(:prev_gesture)
          @calibrated_distance = @distance_level
        #when /PREV-OFF/
        #  @hand_gesture.process_event(:stop_gesture
        when /NEXT/
          @hand_gesture.process_event(:next_gesture)
          @calibrated_distance = @distance_level
        when /CONFIRM/
          @hand_gesture.process_event(:confirm)
        when /SELECT/
          @hand_gesture.process_event(:select)
        #when /NEXT-OFF/
        # @hand_gesture.process_event(:stop_gesture
        #when /STOP-ON/
        #  @hand_gesture.process_event(:stop_gesture
        #when /STOP-OFF/
        #  @hand_gesture.process_event(:stop_gesture
        when /HANDS-2/
          @zoom_level = 0
          @hand_gesture.process_event(:two_hands)
        when /HANDS-1/
          @hand_gesture.process_event(:one_hand)
          puts @hand_gesture.states
        when /HANDS-0/
          @hand_gesture.process_event(:no_hands)
        else
          send_data "ERROR\r\nReceived Unknown data:#{data}\r\n "
      end
    end
  rescue Statemachine::TransitionMissingException => bang
    puts "ERROR\n#{bang}"
  end
end


EventMachine::run do
  require "MINT-core"
  require "one_hand_nav_final"

  DataMapper.setup(:default, { :adapter => "redis", :host =>"0.0.0.0",:port=>6379})

  ARGV.each do|a|
    puts "Argument: #{a}"
  end

  case ARGV[0]
    when "flexible_ticker"
      @hand_gesture = OneHandNavFlexibleTicker.first_or_create(:name => 'handgesture')
    when "static_ticker"
      @hand_gesture = OneHandNavStaticTicker.first_or_create(:name => 'handgesture')
    else
      @hand_gesture = MINT::Interactor.create(:name => 'handgesture')

  end

#@hand_gesture.statemachine.activation = @hand_gesture.method(:activate)



  @host = "0.0.0.0"
  @port = 5000
  EventMachine::start_server @host, @port, StatefulProtocol do |conn|
    conn.hand_gesture=@hand_gesture

    puts "connection..."
  end
  puts "Started server on #{@host}:#{@port}"
end

