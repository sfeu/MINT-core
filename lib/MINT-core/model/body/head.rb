module MINT
  class Head < Element
    attr_accessor :mode
    #property :angle, Integer, :default  => -1
    #property :distance, Integer, :default  => -1


    def initialize_statemachine

      if @statemachine.blank?

        @mode=:tilting

        parser = StatemachineParser.new(self)
        @statemachine = parser.build_from_scxml "#{File.dirname(__FILE__)}/head.scxml"
        @statemachine.reset
      end
    end



    def angle=(angle)
      if @publish_angle
        Juggernaut.publish("head/angle", "#{angle}")
      end
    end

    def start_publish_angle
      @publish_angle=true
    end

    def stop_publish_angle
      @publish_angle=false
    end


    def in_nodding_mode
      return true if @mode.eql? :nodding
      false
    end

    def in_turning_mode
      return true if @mode.eql? :turning
      false
    end

    def in_tilting_mode
      return true if @mode.eql? :tilting
      false
    end
  end
end