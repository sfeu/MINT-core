
module MINT

  class OneHandPoseNavigation < Pose

    def getSCXML
      "#{File.dirname(__FILE__)}/onehandposenavigation.scxml"
    end

    def initialize(attributes = nil)
      super(attributes)

    end
  end
end
