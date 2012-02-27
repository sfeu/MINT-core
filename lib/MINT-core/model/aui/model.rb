# AUI MODEL
module MINT



  require "MINT-core/model/aui/AIO"
  require "MINT-core/model/new/aui/AIO"

  class AIIN < AIO
  end
  require "MINT-core/model/new/aui/AIIN"

  class AIINContinous < AIIN
  end

  class AIINDiscrete <AIIN
  end

  class AIINReference < AIINDiscrete
  end

  class AICommand <AIINDiscrete
  end


 require "MINT-core/model/aui/AIINChoose"

  class AIOUT <AIO
  end
  require "MINT-core/model/new/aui/AIOUT"

  require "MINT-core/model/aui/AIOUTDiscrete"


  class AIOUTContext < AIOUTDiscrete
    property :text, String
  end

  require "MINT-core/model/new/aui/AIOUTDiscrete"

  require "MINT-core/model/aui/AIC"
    require "MINT-core/model/new/aui/AIC"

  class AIOUTContinous < AIOUT
  end
  require "MINT-core/model/new/aui/AIOUTContinous"
  require "MINT-core/model/new/aui/AIINContinous"

end

require "MINT-core/model/aui/AIChoice"

require "MINT-core/model/aui/AISingleChoiceElement"
require "MINT-core/model/aui/AISingleChoice"

require "MINT-core/model/aui/AIMultiChoiceElement"
require "MINT-core/model/aui/AIMultiChoice"

# require "MINT-core/model/aui/AISinglePresence"
  require "MINT-core/model/new/aui/AISinglePresence"