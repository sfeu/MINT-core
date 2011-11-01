module MINT
  require "MINT-core/model/cui/gfx/CIO"

  require "MINT-core/model/cui/gfx/CIC"
  class Button < CIO
  end

  class Image < CIO
     property :path, String
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
      if @statemachine.blank?

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
      aio =  MINT::AIINChoose.first(:name=>self.name)
      if (aio and not aio.is_in? :unchosen)
        aio.sync_event(:unchoose)
      end
      true
    end

    def sync_aio_to_chosen
      aio =  MINT::AIINChoose.first(:name=>self.name)
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
      if @statemachine.blank?

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

  require "MINT-core/model/cui/gfx/screen"

end
