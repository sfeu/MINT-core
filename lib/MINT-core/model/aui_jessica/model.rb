# AUI MODEL
module MINT
  require "MINT-core/model/aui_jessica/AIO"
  require "MINT-core/model/aui_jessica/AIOUT"
  require "MINT-core/model/aui_jessica/AIOUTContinous"
  require "MINT-core/model/aui_jessica/AIContainer"
  require "MINT-core/model/aui_jessica/AISinglePresence"
  require "MINT-core/model/aui_jessica/AISingleChoice"
  require "MINT-core/model/aui_jessica/AIMultiChoice"
  require "MINT-core/model/aui_jessica/AIIN"
  require "MINT-core/model/aui_jessica/Aiindiscrete"
  require "MINT-core/model/aui_jessica/AIINContinous"
  require "MINT-core/model/aui_jessica/AIReference"
  require "MINT-core/model/aui_jessica/AICommand"
  require "MINT-core/model/aui_jessica/AIChoiceElement"
  require "MINT-core/model/aui_jessica/AISingleChoiceElement"
  require "MINT-core/model/aui_jessica/AIMultiChoiceElement"

  class AIO
    #property :data, String
  end

  class AIIN < AIO
  end

  class AIINContinous < AIIN
    #property :min, Integer
    #property :max, Integer
  end

  class AIINDiscrete < AIIN
  end

  class AICommand < AIINDiscrete
  end

  class AIReference < AIINDiscrete
    #property :refers, 'AIO'
  end

  class AIChoiceElement < AIINDiscrete
  end

  class AISingleChoiceElement < AIChoiceElement
  end

  class AIMultiChoiceElement < AIChoiceElement
  end

  class AIOUT <AIO
  end

  class AIContext < AIOUT
    #property :description, String
  end

  class AIOUTContinous < AIOUT
    #property :min, Integer
    #property :max, Integer
  end

  class AIContainer < AIOUT
  end

  class AISinglePresence < AIContainer
  end

  class AISingleChoice < AIContainer
  end

  class AIMultiChoice < AISingleChoice
  end

end

