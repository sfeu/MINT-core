
module MINT
  class Head < Interactor
    #property :angle, Integer, :default  => -1
    #property :distance, Integer, :default  => -1

       def getSCXML
          "#{File.dirname(__FILE__)}/head.scxml"
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

  end
end
