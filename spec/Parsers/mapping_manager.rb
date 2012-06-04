require 'rubygems'
require "bundler/setup"
require 'rexml/document'
require 'rexml/streamlistener'
require "../../MINT-nodejs/Parser/mappings-parser.rb"

class MappingManager
  include REXML
  include StreamListener

  def initialize()
    @mappings = {}
    @callbacks = {}
  end

  # This function parses scxml from a file
  def build_from_scxml(filename)
    source = File.new filename
    Document.parse_stream(source, self)
    @mappings
  end

  # This function parses scxml directly from the string parameter "stringbuffer"
  def build_from_scxml_string(stringbuffer)
    Document.parse_stream(stringbuffer, self)
    @mappings
  end

  def load(xml_file)
    @mappings = build_from_scxml(xml_file)
  end

  def register_callback(mapping_name, callback)
    #If mapping already exists add callback
    #Otherwise save it for later
    if @mappings.has_key? (mapping_name)
      @mappings[mapping_name].state_callback = callback
    else
      @callbacks[mapping_name] = callback
    end
  end

  # This function defines the actions to be taken for each different tag when the tag is opened
  def tag_start(name, attributes)
    case name
      when 'mim'
         #Do I have to store its name?
      when 'include'
         parser = MappingsParser.new
         mapping = parser.build_from_scxml("examples/"+ attributes['href'])
         @mappings[mapping.mapping_name] = mapping

         #If a callback has already been register, add it.
         if @callbacks.has_key? mapping.mapping_name
           mapping.state_callback = @callbacks[mapping.mapping_name]
         end

         #TODO check if callback here or in class initialize
         if @mappings[mapping.mapping_name].state_callback
           p "Mapping #{mapping.mapping_name} loaded"
           @mappings[mapping.mapping_name].state_callback.call(mapping.mapping_name, {:id => mapping.id, :mapping_state => :loaded})
         end
         if attributes['start'] == "true"
           mapping.start
         end
    end
  end
end
