  require "MINT-core/model/cui/gfx/CIO"
  require "MINT-core/model/cui/gfx/CIC"
  require "MINT-core/model/cui/gfx/button"


  module MINT
    class Image < CIO
      property :path, String
    end

    class JCarouselImage < Image

    end


    class Slider < CIO

    end

    class ProgressBar < CIO

    end

    class HTMLHead < CIO
      property :css, String
      property :js, String
    end

    class Selectable_sync_callback < CIO_sync_callback
      def sync_aio_to_unchosen
        true
      end

      def sync_aio_to_chosen
        true
      end
    end
  # Abstract class to handle objects that can be selected
    class Selectable < CIO
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

                    event :hide, :hidden

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
              end
            end
          end
        end
      end

      def sync_event(event)
        process_event(event, Selectable_sync_callback.new)
      end

      def sync_aio_to_unchosen
        aio =  MINT::AIChoiceElement.first(:name=>self.name)
        if (aio and not aio.is_in? :unchosen)
          aio.sync_event(:unchoose)
        end
        true
      end

      def sync_aio_to_chosen
        aio =  MINT::AIChoiceElement.first(:name=>self.name)
        if (aio and not aio.is_in? :chosen)
          aio.sync_event(:choose)
        end
        true
      end
    end

    class FurnitureItem < Selectable
      property :title, String
      property :price, String
      property :image, String
      property :description, String
    end

    class SingleHighlight < CIC
    end

    # adaptation of jCarousel http://sorgalla.com/projects/jcarousel/
    class JCarousel < CIC

      # Specifies whether the carousel appears in horizontal or vertical orientation. Changes the carousel from a left/right style to a up/down style carousel.
      property :vertical	, Boolean, :default  => false

      # Specifies whether the carousel appears in RTL (Right-To-Left) mode.
      property :rtl	, Boolean	, :default  => false

      #	The index of the item to start with.
      property :start	, Integer	, :default  => 1

      #The index of the first available item at initialisation.
      property :jacrousel_offset	, Integer	, :default  => 1

      # Number of existing <li> elements if size is not passed explicitly	The number of total items.
      property :size	, Integer

      # The number of items to scroll by.
      property :scroll	, Integer	, :default  => 3

      #If passed, the width/height of the items will be calculated and set depending on the width/height of the clipping, so that exactly that number of items will be visible.
      property :visible	, Integer	# , :default  => nil

      #The speed of the scroll animation as string in jQuery terms ("slow" or "fast") or milliseconds as integer (See jQuery Documentation). If set to 0, animation is turned off.
      property :animation	, String	, :default  => "fast"

      #The name of the easing effect that you want to use (See jQuery Documentation).
      property :easing	, String	#, :default  => nil

      # Specifies how many seconds to periodically autoscroll the content. If set to 0 (default) then autoscrolling is turned off.
      property :auto	, Integer	, :default  => 0

      #Specifies whether to wrap at the first/last item (or both) and jump back to the start/end. Options are "first", "last", "both" or "circular" as string. If set to null, wrapping is turned off (default).
      property :wrap	, String	#, :default  => nil
    end


    # http://caroufredsel.frebsite.nl/
    # jQuery.carouFredSel is a plugin that turns any kind of HTML element into a carousel. It can scroll one or
    # multiple items simultaneously,horizontal or vertical, infinite and circular, automatically or by user interaction.
    # It is dual licensed under the MIT and GPL licenses.




    class ARFrame <  CIO

    end

    class CheckBox < Selectable
    end

    class CheckBoxGroup < CIC
    end

    class RadioButton < Selectable
    end

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

    class RadioButtonGroup < CIC
    end

    class BasicText < CIO
    end

    class Label <CIO
    end
  end

  require "MINT-core/model/cui/gfx/screen"

  require "MINT-core/model/cui/gfx/caroufredsel"