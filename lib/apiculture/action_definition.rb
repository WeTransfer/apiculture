# Describes a single API action (route). Is used internally by Apiculture.
class Apiculture::ActionDefinition
  attr_accessor :description
  attr_accessor :http_verb
  attr_accessor :path
  
  attr_reader :parameters
  attr_reader :route_parameters
  attr_reader :responses
  
  def all_parameter_names_as_strings
    @parameters.map(&:name_as_string) + @route_parameters.map(&:name_as_string)
  end
  
  def defines_responses?
    @responses.any?
  end
  
  def defines_request_params?
    @parameters.any?
  end
  
  def defines_route_params?
    @route_parameters.any?
  end
  
  def initialize
    @parameters, @route_parameters, @responses = [], [], []
  end

  def to_tagged_markdown(mountpoint)
    md = Apiculture::MethodDocumentation.new(self, mountpoint).to_markdown
    TaggedMarkdown.new(md, 'apiculture-method')
  end
end