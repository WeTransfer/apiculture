# Allows brief definitions of APIs for documentation and parameter checks
module Apiculture
  require_relative 'apiculture/version'
  require_relative 'apiculture/indifferent_hash'
  require_relative 'apiculture/action'
  require_relative 'apiculture/sinatra_instance_methods'
  require_relative 'apiculture/action_definition'
  require_relative 'apiculture/markdown_segment'
  require_relative 'apiculture/timestamp_promise'
  require_relative 'apiculture/app_documentation'
  require_relative 'apiculture/openapi_documentation'

  def self.extended(in_class)
    in_class.send(:include, SinatraInstanceMethods)
    super
  end

  class Void
    def <<(_item); end
    def map; []; end
    def select; []; end
  end

  IDENTITY_PROC = ->(arg) { arg }

  AC_APPLY_TYPECAST_PROC = ->(cast_proc_or_method, v) {
    cast_proc_or_method.is_a?(Symbol) ? v.public_send(cast_proc_or_method) : cast_proc_or_method.call(v)
  }

  AC_CHECK_PRESENCE_PROC = ->(name_as_string, params) {
    params.has_key?(name_as_string) or raise MissingParameter.new(name_as_string)
  }

  AC_CHECK_TYPE_PROC = ->(param, value) {
    param.matchable === value or raise ParameterTypeMismatch.new(param, value.class)
  }

  class Parameter < Struct.new(:name, :description, :required, :matchable, :cast_proc_or_method)
    # Return Strings since Sinatra prefers string keys for params{}
    def name_as_string; name.to_s; end
  end

  class RouteParameter < Parameter
  end

  class PossibleResponse < Struct.new(:http_status_code, :description, :jsonable_object_example)
    def no_body?
      jsonable_object_example.nil?
    end
  end

  # Indicates where this API will be mounted. This is only used
  # for the generated documentation. In general, this should match
  # the SCRIPT_NAME of the Sinatra application when it will be called.
  # For example, if you use this in your +config.ru+:
  #
  #     map('/api/v3') { run MyApi }
  #
  # then it is handy to set that with +mounted_at+ as well so that the API
  # documentation references the mountpoint:
  #
  #     mounted_at '/api/v3'
  #
  # Again: this does not change the way requests are handled in any way,
  # it just alters the documentation output.
  def mounted_at(path)
    @apiculture_mounted_at = path.to_s.gsub(/\/$/, '')
  end

  # Inserts the generation timestamp into the documentation at this point.
  # The timestamp will be not very precise (to the minute) and in UTC time
  def documentation_build_time!
    apiculture_stack << Apiculture::TimestampPromise
  end

  # Inserts a literal Markdown string into the documentation at this point.
  # For instance, if used after an API method declaration, it will insert
  # the header between the API methods in the doc.
  #
  #     api_method :get, '/foo/bar' do
  #       #...
  #     end
  #     markdown_string "# Subsequent methods do thing to Bars"
  #     api_method :get, '/bar/thing' do
  #       #...
  #     end
  def markdown_string(str)
    apiculture_stack << MarkdownSegment.new(str)
  end

  # Inserts the contents of the file at +path+ into the documentation, using +markdown_string+.
  # For instance, if used after an API method declaration, it will insert
  # the header between the API methods in the doc.
  #
  #     markdown_file "SECURITY_CONSIDERATIONS.md"
  #     api_method :get, '/bar/thing' do
  #       #...
  #     end
  def markdown_file(path_to_markdown)
    md = File.read(path_to_markdown).encode(Encoding::UTF_8)
    markdown_string(md)
  end

  # Describe the API method that is going to be defined
  def desc(action_description)
    @apiculture_action_definition ||= ActionDefinition.new
    @apiculture_action_definition.description = action_description.to_s
  end

  # Add an optional parameter for the API call
  def param(name, description, matchable, cast: IDENTITY_PROC)
    @apiculture_action_definition ||= ActionDefinition.new
    @apiculture_action_definition.parameters << Parameter.new(name, description, required=false, matchable, cast)
  end

  # Add a requred parameter for the API call
  def required_param(name, description, matchable, cast: IDENTITY_PROC)
    @apiculture_action_definition ||= ActionDefinition.new
    @apiculture_action_definition.parameters << Parameter.new(name, description, required=true, matchable, cast)
  end

  # Describe a parameter that has to be included in the URL of the API call.
  # Route parameters are always required, and all the parameters specified
  # using +route_param+ should also be included in the path given for the route
  # definition
  def route_param(name, description, matchable = String, cast: IDENTITY_PROC)
    @apiculture_action_definition ||= ActionDefinition.new
    @apiculture_action_definition.route_parameters << RouteParameter.new(name, description, required=false, matchable, cast)
  end

  # Add a possible response, specifying the code and the JSON Response by example.
  # Multiple response packages can be specified.
  def responds_with(http_status, description, example_jsonable_object = nil)
    @apiculture_action_definition ||= ActionDefinition.new
    @apiculture_action_definition.responses << PossibleResponse.new(http_status, description, example_jsonable_object)
  end

  DefinitionError = Class.new(StandardError)
  ValidationError = Class.new(StandardError)

  class RouteParameterNotInPath < DefinitionError; end
  class ReservedParameter < DefinitionError; end
  class ConflictingParameter < DefinitionError; end

  # Gets raised when a parameter is missing
  class MissingParameter < ValidationError
    def initialize(parameter_name)
      super "Missing parameter :#{parameter_name}"
    end
  end

  # Gets raised when a parameter is supplied and has a wrong type
  class ParameterTypeMismatch < ValidationError
    def initialize(ac_parameter, received_ruby_type)
      parameter_name, expected_type = ac_parameter.name, ac_parameter.matchable
      received_type = received_ruby_type
      super "Received #{received_type}, expected #{expected_type.inspect} for :#{parameter_name}"
    end
  end

  # Returns a Proc that calls the strong parameters to check the presence/types
  def parametric_validator_proc_from(parametric_validators, implicitly_defined_route_parameter_names)
    required_params = parametric_validators.select{|e| e.required }
    # Return a lambda that will be called with the Sinatra params
    parametric_validation_blk = ->{
      # Within this block +params+ is the Sinatra's instance params
      # Ensure the required parameters are present first, before applying casts/validations etc.
      required_params.each { |param| AC_CHECK_PRESENCE_PROC.call(param.name_as_string, params) }
      parametric_validators.each do |param|
        param_name = param.name_as_string
        next unless params.has_key?(param_name) # this is checked via required_params

        # Apply the type cast and save it (since using our override we can mutate the params)
        value_after_type_cast = AC_APPLY_TYPECAST_PROC.call(param.cast_proc_or_method, params[param_name])
        params[param_name] = value_after_type_cast

        # Ensure the typecast value adheres to the enforced Ruby type
        AC_CHECK_TYPE_PROC.call(param, params[param_name])
      end

      # The following only applies if the app does not use strong_parameters -
      # this makes use of parameter mutability again to kill the parameters that are not permitted
      # or mentioned in the API specification. We need to keep the params which are specified in the
      # route but not documented via Apiculture though
      unexpected_parameters = Set.new(params.keys.map(&:to_s)) -
        Set.new(parametric_validators.map(&:name).map(&:to_s)) -
        Set.new(implicitly_defined_route_parameter_names.map(&:to_s))

      unexpected_parameters.each do | parameter_to_discard |
        # TODO: raise or record a warning
        if env['rack.logger'].respond_to?(:warn)
          env['rack.logger'].warn "Discarding disallowed parameter #{parameter_to_discard.inspect}"
        end
        params.delete(parameter_to_discard)
      end
    }
  end

  # Serve the documentation for the API at the given URL
  def serve_api_documentation_at(url)
    get(url) do
      content_type :html
      self.class.api_documentation.to_html
    end
  end

  # Returns an +AppDocumentation+ object for all actions defined so far.
  #
  #   MyApi.api_documentation.to_markdown #=> "..."
  #   MyApi.api_documentation.to_html #=> "..."
  def api_documentation
    AppDocumentation.new(self, @apiculture_mounted_at.to_s, @apiculture_actions_and_docs || [])
  end

  # Define an API method. Under the hood will call the related methods in Sinatra
  # to define the route.
  def api_method(http_verb, path, options={}, &blk)
    action_def = (@apiculture_action_definition || ActionDefinition.new)
    action_def.http_verb = http_verb
    action_def.path = path

    # Ensure no reserved Sinatra parameters are used
    all_parameter_names = action_def.all_parameter_names_as_strings
    %w( splat captures ).each do | reserved_param |
      if all_parameter_names.include?(reserved_param)
        raise ReservedParameter.new(":#{reserved_param} is a reserved magic parameter name in Sinatra")
      end
    end

    # Ensure no conflations between route/req params
    seen_params = {}
    all_parameter_names.each do |e|
      if seen_params[e]
        raise ConflictingParameter.new(":#{e} mentioned twice as a possible parameter. Note that URL" +
          " parameters and request parameters share a namespace.")
      else
        seen_params[e] = true
      end
    end

    # Ensure the path has the route parameters that were predeclared
    action_def.route_parameters.map(&:name).each do | route_parameter_key |
      unless path.include?(':%s' % route_parameter_key)
        raise RouteParameterNotInPath.new("Parameter :#{route_parameter_key} not present in path #{path.inspect}")
      end
    end

    # TODO: ensure all route parameters are documented

    # Pick out all the defined parameters and set up a block that can validate them
    # when the action is called. With that, set up the actual Sinatra method that will
    # respond to the request. We take care to preserve all the params that have NOT been documented
    # using Apiculture but _were_ in fact specified in the actual path.
    route_parameter_names = path.scan(/:([^:\/]+)/).flatten.map(&:to_sym)
    parametric_checker_proc = parametric_validator_proc_from(action_def.parameters + action_def.route_parameters, route_parameter_names)
    public_send(http_verb, path, **options) do |*matched_sinatra_route_params|
      # Extract all the parameter names from the route path as given to the method
      route_parameters = Hash[route_parameter_names.zip(matched_sinatra_route_params)]

      # Apply route parameter checks, but only to params that were defined in the Apiculture action descriptor.
      # All the other params have to go via bypass.
      checked_route_parameters = action_def.route_parameters.select {|par| route_parameter_names.include?(par.name) }
      checked_route_parameters.each do |route_param|
        # Apply the type cast and save it (since using our override we can mutate the params)
        value_from_route_params = route_parameters.fetch(route_param.name)
        value_after_type_cast = AC_APPLY_TYPECAST_PROC.call(route_param.cast_proc_or_method, value_from_route_params)
        # Ensure the typecast value adheres to the enforced Ruby type
        AC_CHECK_TYPE_PROC.call(route_param, value_after_type_cast)
        # ..and overwrite it in the route parameters hash
        route_parameters[route_param.name] = value_after_type_cast
      end
      # Execute parametric checks on all the OTHER params (forms etc.)
      instance_exec(&parametric_checker_proc)
      # Execute the original action via instance_exec, passing along the route args
      instance_exec(*route_parameters.values, &blk)
    end

    # Reset for the subsequent action definition
    @apiculture_action_definition = ActionDefinition.new
    # and store the just defined action for future use
    apiculture_stack << action_def
  end

  def apiculture_stack
    if environment == "development"
      @apiculture_actions_and_docs ||= []
    else
      @apiculture_actions_and_docs ||= Void.new
    end
    @apiculture_actions_and_docs
  end

  # Based on the RACK_ENV it will generate documentation or not
  def environment
    @environment ||= ENV.fetch("RACK_ENV", "development")
  end
end
