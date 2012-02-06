
module MINT
  class Agent
    attr_reader :running_mappings

    def initialize(connection_options = { :adapter => "redis", :host =>"localhost",:port=>6379})
      DataMapper.setup(:default, connection_options)
      DRb.start_service
      @running_mappings = []
#       DataMapper::Logger.new("data.log", :debug)
    end

    def addMapping(mapping)
      m = mapping.execute

      if not m.is_a? Array
        m= [m]
      end
      @running_mappings += m
    end

    def run
      @running_mappings.each do |thread|
        thread.join
      end
    end
  end
end
