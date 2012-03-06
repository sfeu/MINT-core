require "rubygems"
require "eventmachine"

class T
  def initialize
		@a = 0
	end

	def test
    @a +=1
    p @a
	end
end

EM.run do

timer = EventMachine::PeriodicTimer.new(5) do
   puts "the time is #{Time.now}"
   timer.cancel if (n+=1) > 5
 end

end