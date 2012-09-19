require 'rubygems'
require "bundler/setup"
require 'rexml/document'
require 'rexml/streamlistener'
module MINT
  class MappingParser
    include REXML
    include StreamListener

    def initialize()
      @mapping_name  #actual name of the mapping
      @mapping_type  #type of the mapping: complementary, sequential, ...
      @observations = Array.new #will store the observations
      @actions = Array.new #will store the actions
      @mapping #actual mapping
    end

    # This function parses scxml from a file
    def build_from_scxml(filename)
      source = File.new filename
      Document.parse_stream(source, self)
      @mapping
    end

    # This function parses scxml directly from the string parameter "stringbuffer"
    def build_from_scxml_string(stringbuffer)
      Document.parse_stream(stringbuffer, self)
      @mapping
    end

    # This function defines the actions to be taken for each different tag when the tag is opened
    def tag_start(name, attributes)
      case name
        when 'mapping'
          @mapping_name = attributes['name']
        when 'operator'
          @mapping_type = attributes['type']
          @mapping_id = attributes['id']
        when 'observation'
          observation_states = Array.new
          observation_hash = Hash.new
          observation_hash[:element] = attributes['interactor']
          observation_hash[:name] = attributes['name']
          observation_hash[:id] = attributes['id']
          attributes['states'].split("|").each do |s| observation_states << s.to_sym end   if attributes['states']
          observation_hash[:states] = observation_states
          observation_hash[:process] = attributes['process'].to_s.to_sym if attributes['process']
          observation_hash[:result] = attributes['result'] if attributes['result']

          if attributes['type'] and attributes['type'].eql? "negation"
            @observations << NegationObservation.new(observation_hash)
          else
            @observations << Observation.new(observation_hash)
          end
        when 'backend'
          backend_call = MINT::const_get(attributes['class']).method(attributes['call'].to_sym) # TODO figure out a way that this can work
          @actions << BackendAction.new(:call => backend_call,:parameter => attributes['parameter'], :id => attributes['id'])
        when 'bind'
          backend_call = MINT::const_get(attributes['class']).method(attributes['transformation'].to_sym) if attributes['transformation']
          @actions << BindAction.new(:id => attributes['id'], :elementIn => attributes['interactor_in'], :nameIn => attributes['name_in'], :attrIn => attributes['attr_in'],
                                     :elementOut => attributes['interactor_out'], :nameOut => attributes['name_out'], :attrOut => attributes['attr_out'],:transform => backend_call)
        when 'event'
          @actions << EventAction.new(:id => attributes['id'], :event => attributes['type'].to_sym, :target => attributes['target'])
        else
      end
    end

    # This function defines the actions to be taken for each different tag when the tag is closed
    def tag_end(name)
      case name
        when 'operator'
          case @mapping_type
            when 'complementary'
              @mapping = ComplementaryMapping.new(:id => @mapping_id, :name => @mapping_name, :observations => @observations, :actions => @actions)
            when 'sequential'
              @mapping = SequentialMapping.new(:id => @mapping_id, :name => @mapping_name, :observations => @observations, :actions => @actions)
            else
          end
        else
      end
    end

    def text(text)
    end

    def xmldecl(version, encoding, standalone)
    end
  end
end