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

    class MarkableRadioButton < RadioButton
      def initialize_statemachine
        if @statemachine.nil?

          @statemachine = Statemachine.build do

            superstate :CIO do
              trans :initialized,:position,:positioning
              trans :positioning,:calculated,:positioned, :store_calculated_values_in_model
              trans :positioned, :display, :presenting
              trans :disabled, :hide, :hidden
              trans :hidden,:display, :presenting


              parallel :p do
                statemachine :s1 do
                  superstate :presenting do
                    on_entry :sync_aio_to_presented

                    state :displayed do
                      on_entry :sync_aio_to_defocus
                    end

                    state :highlighted  do
                      on_entry :sync_aio_to_focused
                    end

                    trans :displayed, :highlight, :highlighted
                    trans :highlighted,:unhighlight, :displayed
                    trans :highlighted, :up, :displayed, :highlight_up
                    trans :highlighted, :down, :displayed, :highlight_down
                    trans :highlighted, :left, :displayed, :highlight_left
                    trans :highlighted, :right, :displayed, :highlight_right

                    event :disable, :disabled
                    event :hide, :hidden

                  end
                end
                statemachine :s2 do
                  superstate :selection do
                    trans :listed, :select, :selected
                    trans :selected, :select, :listed

                    state :listed do
                      on_entry :sync_aio_to_unchosen
                    end

                    state :selected  do
                      on_entry :sync_aio_to_chosen
                    end
                  end
                end
                statemachine :s3 do
                  superstate :marker do
                    trans :unmarked, :mark, :marked
                    trans :marked, :unmark, :unmarked
                  end
                end
              end
            end
          end
        end
      end
    end


    class BasicText < CIO
    end

    class Label <CIO
    end
  end

  require "MINT-core/model/cui/gfx/screen"

  require "MINT-core/model/cui/gfx/caroufredsel"