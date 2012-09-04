require 'rubygems'
require "bundler/setup"
require 'rexml/document'
require 'rexml/streamlistener'

class MappingManager
  include REXML
  include StreamListener

  def initialize()
    @mappings = {}
    @callbacks = {}
    @file_path = nil

    #callback that will be called if all mappings with attribute == run have been activated == subscribed
    @started_cb = nil

    # contains mappings that have been loaded ans started but whose observations have not finished subscribing
    @waiting_mappings = []

    #will be true if all mappings have been parsed
    @finished_parsing = false
  end

  def finished_parsing
    @finished_parsing = true
    wait_for_all_mappings_activated(nil)
  end

  # This function parses scxml from a file
  def build_from_scxml(filename)
    source = File.new filename
    Document.parse_stream(source, self)
    finished_parsing()
    @mappings
  end

  # This function parses scxml directly from the string parameter "stringbuffer"
  def build_from_scxml_string(stringbuffer)
    Document.parse_stream(stringbuffer, self)
    finished_parsing()
    @mappings
  end

  def load(xml_file)
    @file_path = File.expand_path(File.dirname(xml_file))
    @mappings = build_from_scxml(xml_file)
    self
  end

  def get_mappings
    @mappings.keys
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
         parser = MINT::MappingParser.new
         mapping = parser.build_from_scxml(@file_path +"/"+ attributes['href'])
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
           @waiting_mappings << mapping.mapping_name
           mapping.start.activated_callback {wait_for_all_mappings_activated(mapping)}

         end
    end
  end

  def wait_for_all_mappings_activated(mapping)
      @waiting_mappings.delete mapping.mapping_name if mapping
      @started_cb.call if @started_cb and @finished_parsing and @waiting_mappings.length == 0
  end

  def started(&block)
    @started_cb = block
  end
end
