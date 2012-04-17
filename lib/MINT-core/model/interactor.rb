module MINT
  # An {Interactor} is the basic abstract element of the complete MINT markup language. Nearly all  other
  # classes are derived  from {MINT::Interactor} since early everything can be activated by {#state} and has
  # a {#name}. 
  #
  class Interactor
    include DataMapper::Resource

    def getModel
      "core"
    end

    private


    property :classtype, Discriminator
    property :mint_model, String, :default => lambda { |r,p| r.getModel}, :key=>true

    # Each abstract  {Interactor} needs to have a name that we will use as the primary key for each model.
    property :name, String, :key => true
    #property :id, Serial

    # States of the {Interactor} Reflects the actual atomic states of the interactors state machine.
    property :states, String

    # reflects all active states including abstract superstates of an interactor as a |-seperated state id list
    property :abstract_states, String

    #always contains the new atomic states that have been entered by the event that has been processed - especially useful for parallel states
    property :new_states, String

    protected
    before :save, :save_statemachine
    after :create, :init_statemachine

    public

    def init_statemachine
      initialize_statemachine true
    end


    PUBLISH_ATTRIBUTES = [:name,:states,:abstract_states,:new_states,:classtype, :mint_model]

    def self.create_channel_name
      a = [self]
      a.unshift a.first.superclass while (a.first!=MINT::Interactor)
      a.map!{|x| x.to_s.split('::').last}
      a.join(".")
    end

    def create_attribute_channel_name(attribute)
      self.class.create_channel_name+".#{attribute}.#{self.name}"
    end

    def create_channel_w_name
      self.class.create_channel_name+".#{self.name}"
    end


    def self.class_from_channel_name(channel)
      Object.const_get("MINT").const_get channel.split('.').last
    end

    def publish_update(states,abstract_states, atomic_states)


      as_copy = attribute_get(:abstract_states)
      new_copy = attribute_get(:new_states)
      states_copy = attribute_get(:states)

      attribute_set(:abstract_states, abstract_states.join('|'))
      attribute_set(:new_states, states.join('|'))
      attribute_set(:states, atomic_states.join('|'))

      RedisConnector.pub.publish self.class.create_channel_name, self.to_json(:only => self.class::PUBLISH_ATTRIBUTES)

      attribute_set(:abstract_states, as_copy)
      attribute_set(:new_states, new_copy)
      attribute_set(:states, states_copy)
    end

    def self.notify(action,query,callback,time = nil)
      RedisConnector.sub.subscribe("#{self.create_channel_name}")

      RedisConnector.sub.on(:message) { |channel, message|
        found=JSON.parse message
        puts query.inspect
        query.keys.each do |k|
          if found[k.to_s]
            a = found[k.to_s]
            query[k].each do |e|
              puts "found #{e} a:#{a.inspect}"
              if a.include? e
                callback.call found
                break
              end
            end
          end
        end
      }
    end


    def self.wait(action,query,callback,time = nil)
      # q = scoped_query(query)
      # q.repository.notify(action,query,callback,self,q, time)
    end

    def to_dot(filename)
      if not @statemachine
        initialize_statemachine
      end
      @statemachine.to_dot(:output => filename)
    end
    def states
      if not @statemachine
        initialize_statemachine
        recover_statemachine
      end
      @statemachine.states_id
    end

    def new_states
      if attribute_get(:new_states)
        return attribute_get(:new_states).split("|").map &:to_sym if attribute_get(:new_states).class!=Array
        return attribute_get(:new_states)
      else return []
      end
    end

    def states= states
      if not @statemachine # if called on element creation using the states hash!
        initialize_statemachine
      end
      @statemachine.states=states
      save_statemachine
    end

    def initialize(attributes = nil)
      super(attributes)

  #    recover_statemachine
    end

    # The sync event method is overwritten in the derived classes to prevent synchronization cycles by setting an empty callback
    def sync_event(event)
      process_event(event)
    end

    #allows to set variables that will be passed as parameters to the actions
    def process_event_vars(event, *vars)
      process_event(event,nil,vars)
    end

    def process_event(event, callback=nil, vars = nil)

      states = process_event!(event,callback,vars)
      if states
        save_statemachine
        states
      else
        false
      end
    end

    def process_event!(event, callback=nil,vars=nil)
      if not @statemachine
        initialize_statemachine
        recover_statemachine
      end
      if callback
        @statemachine.context = callback
      else
        @statemachine.context = self
      end
      begin
        old_states = @statemachine.states_id
        old_abstract_states = @statemachine.abstract_states
        @statemachine.process_event(event,*vars)
        calc_new_states = @statemachine.states_id-old_states
        calc_new_states = calc_new_states + (@statemachine.abstract_states - old_abstract_states)
        calc_new_states = @statemachine.states_id  if calc_new_states.length==0
        attribute_set(:new_states, calc_new_states.join('|'))
      rescue Statemachine::TransitionMissingException
        p "#{self.name} is in state #{self.states} and could not handle #{event}"
        return false
      end
      return @statemachine.states_id
    end

    def is_in?(state)
      if not @statemachine

        #return true if (attribute_get(:states).split('|').map &:intern).include? state.intern
        #return true if (attribute_get(:abstract_states).split('|').map &:intern).include? state.intern
        #return false
        initialize_statemachine
        recover_statemachine
      end
      @statemachine.In(state)
    end


    def getSCXML
      "#{File.dirname(__FILE__)}/interactor.scxml"
    end

    protected

    def initialize_statemachine(publish_initialize = false)
      if @statemachine.nil?
        parser = StatemachineParser.new(self)
        @statemachine = parser.build_from_scxml getSCXML

        @statemachine.activation=self.method(:publish_update)

        @statemachine.reset(nil,publish_initialize)

      end
    end

    private

    def save_statemachine
      if not @statemachine
        initialize_statemachine true
        recover_statemachine
      end
      attribute_set(:states, @statemachine.states_id.join('|'))
      attribute_set(:abstract_states, @statemachine.abstract_states.join('|'))
      # attribute_set(:new_states,new_states) if new_states and new_states.length>0 # second condition to
      save!
      # publish_update
    end


    # @TODO check this for parallel states!
    def recover_statemachine
      if (@statemachine.nil?)
        initialize_statemachine
      end
      if attribute_get(:states)
        if attribute_get(:states).is_a? Array # @TODO this should not occur!!
          @statemachine.states=attribute_get(:states)
        else
          @statemachine.states=attribute_get(:states).split('|').map &:intern
        end

      else
        attribute_set(:states, @statemachine.states_id.join('|'))
        attribute_set(:abstract_states, @statemachine.abstract_states.concat(@statemachine.states_id).join('|'))
      end
      if not attribute_get(:new_states)
        attribute_set(:new_states, @statemachine.states_id.join('|'))
      end
    end

    def is_set(attribute)
      self.attribute_get(attribute)!=nil
    end
  end

  class IR <Interactor
  end

  class IN < IR
  end

end
