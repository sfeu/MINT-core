module MINT

  # Basic abstract class to define a mapping, which specifies a communication between model agents.
  # Therefore ia mapping listens to a source model of another agents' model for actions like e.g. new elements,
  # updates to elements or element removals.
  #
  class Mapping
    attr_accessor :source_model, :on_action, :execute

    # A mapping is initialized with
    # @param [Class] source_model the other agents' model to listen to for events
    # @param [String] action  to the tuple space that should be listened to. This is one of "take", "read", "write"
    # @param [Method] execute this method of the agent that runs the mapping, the specified action has happened.
    # @param [Method] inital method to call upon initialization of the mapping without the action to be happened, but scans the model for already happened events (write) and executes the method with these data.
    #
    def initialize (source_model,action,execute,initial=nil)
      @source_model = source_model
      @execute = execute
      @initial = initial
      @on_action = action
    end

    # Starts the mapping thread to listen to events
    #
    def execute
      raise NotImplementedError, "#{self.class}#execute not implemented"
    end

    def publish_events(events)
#      p "in check OR cond #{@conditions.inspect}"

      events.each do |c,event|
        c.each do |model,state|
          state.each do |s|
            result=model.first( :abstract_states=> /(^|\|)#{Regexp.quote(s)}/)
            if not result.nil?
              p "Sending #{event} to #{result.name}"
              p result.inspect
              p result.process_event(event)
            end
          end
        end
      end
      true
    end
  end
end