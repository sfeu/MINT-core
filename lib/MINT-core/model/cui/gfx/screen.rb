module MINT
  class Screen < Interactor
    property :root, String

    PUBLISH_ATTRIBUTES += [:root ]

    protected
    def initialize_statemachine
      if @statemachine.blank?
        @statemachine = Statemachine.build do
          trans :initialized, :calculate, :calculating
          trans :calculating, :done, :finished
          trans :finished, :calculate, :calculating
        end
      end
    end

  end
end