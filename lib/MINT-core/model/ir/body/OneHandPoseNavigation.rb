
module MINT

  class OneHandPoseNavigation < HandPose

    def getSCXML
      "#{File.dirname(__FILE__)}/onehandposenavigation.scxml"
    end

    def initialize(attributes = nil)
      super(attributes)

      start
    end
  end
end
