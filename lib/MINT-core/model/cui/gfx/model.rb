  require "MINT-core/model/cui/gfx/CIO"
  require "MINT-core/model/cui/gfx/CIC"
  require "MINT-core/model/cui/gfx/button"


  module MINT
    class Image < CIO
      property :path, String
    end


    class Slider < CIO

    end

    class MinimalOutputSlider < CIO

    end

    class MinimalVerticalOutputSlider < CIO

        end

    class ProgressBar < CIO

    end

    class HTMLHead < CIO
      property :css, String
      property :js, String
    end

    #
    #class FurnitureItem < Selectable
    #  property :title, String
    #  property :price, String
    #  property :image, String
    #  property :description, String
    #end

    class SingleHighlight < CIC
    end


    class ARFrame <  CIO

    end

    #class CheckBox < Selectable
    #end

    class CheckBoxGroup < CIC
    end

    require "MINT-core/model/cui/gfx/RadioButton"
    require "MINT-core/model/cui/gfx/RadioButtonGroup"
    require "MINT-core/model/cui/gfx/MarkableRadioButton"

    class BasicText < CIO
    end

    class Label <CIO
    end
  end

  require "MINT-core/model/cui/gfx/screen"

  require "MINT-core/model/cui/gfx/caroufredsel"