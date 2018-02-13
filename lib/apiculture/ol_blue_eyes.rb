# The minimum possible/viable subset of the Sinatra
# instance methods which are likely to be used within
# a single action
class Apiculture::OlBlueEyes
  def initialize(callable)
    @callable = callable
    @status = 200
  end

  def route_params
    @env['apiculture.route_params']
  end

  def params
    @request.params
  end

  def status(status_code)
    @status = status_code.to_i
  end

  def halt(rack_status, rack_headers, rack_body)
    
  end

  def call(env)
    @env = env
    @request = Rack::Request.new(env)

    body_string_or_rack_triplet = instance_exec(&@callable)
    if rack_triplet?(body_string_or_rack_triplet)
      return body_string_or_rack_triplet
    end

    [@status, {}, [body_string_or_rack_triplet]]
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
