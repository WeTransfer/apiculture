# The minimum possible/viable subset of the Sinatra
# instance methods which are likely to be used within
# a single action
class Apiculture::OlBlueEyes
  attr_reader :request
  attr_reader :env

  def initialize(callable)
    @callable = callable
    @status = 200
    @content_type = 'text/plain'
  end

  def content_type(new_type)
    @content_type = Rack::Mime.mime_type('.%s' % new_type)
  end

  def route_params
    @env['apiculture.route_params']
  end

  def params
    # We let the route params take precedence
    @request.params.merge(@route_params)
  end

  def status(status_code)
    @status = status_code.to_i
  end

  def halt(rack_status, rack_headers, rack_body)
    
  end

  def call(env)
    @env = env
    @request = Rack::Request.new(env)
    @route_params = env.fetch('apiculture.route_params', {})

    # Execut the action in a Sinatra-like fashion
    body_string_or_rack_triplet = instance_exec(*@route_params.values, &@callable)

    if rack_triplet?(body_string_or_rack_triplet)
      return body_string_or_rack_triplet
    end

    [@status, {'Content-Type' => @content_type}, [body_string_or_rack_triplet]]
  end

  def rack_triplet?(maybe_triplet)
    maybe_triplet.is_a?(Array) &&
    maybe_triplet.length == 3 &&
    maybe_triplet[0].is_a?(Integer) &&
    maybe_triplet[1].is_a?(Hash) &&
    maybe_triplet[1].keys.all? {|k| k.is_a?(String) } &&
    maybe_triplet[2].respond_to?(:each)
  end
end
