# AUI MODEL
module MINT



  require "MINT-core/model/aui/AIO"

  class AIIN < AIO
  end

  class AIINContinous < AIIN
  end

  class AIINDiscrete <AIIN
  end

  require "MINT-core/model/aui/AIReference"

  class AICommand <AIINDiscrete
  end


 require "MINT-core/model/aui/AIINChoose"

  class AIOUT <AIO
  end

  require "MINT-core/model/aui/AIOUTDiscrete"

  class AIOUTContext < AIOUTDiscrete
    property :text, String
  end

  class AIOUTContinous < AIOUT
  end

  require "MINT-core/model/aui/AIC"

end

require "MINT-core/model/aui/AISingleChoiceElement"
require "MINT-core/model/aui/AISingleChoice"

require "MINT-core/model/aui/AIMultiChoiceElement"
require "MINT-core/model/aui/AIMultiChoice"

require "MINT-core/model/aui/AISinglePresence"
