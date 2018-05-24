require'mustermann'

class Apiculture::App

  class << self
    def use(middlreware_factory, middleware_options, &middleware_blk)
      @middleware_configurations ||= []
      @middleware_configurations << [middleware_factory, middleware_options, middleware_blk]
    end

    def middleware_configurations
      @middleware_configurations || []
    end

    def get(url, **options, &handler_blk)
      define_action :get, url, options, &handler_blk
    end

    def post(url, **options, &handler_blk)
      define_action :post, url, options, &handler_blk
    end

    def put(url, **options, &handler_blk)
      define_action :put, url, options, &handler_blk
    end

    def delete(url, **options, &handler_blk)
      define_action :delete, url, options, &handler_blk
    end

    def actions
      @actions || []
    end

    def define_action(http_method, url_path, **options, &handler_blk)
      @actions ||= []
      @actions << [http_method.to_s.upcase, url_path, options, handler_blk]
    end
  end

  def perform_action_with_handler_block(env, route_params, action_handler_callable)
    env['apiculture.route_params'] = route_params
    Apiculture::OlBlueEyes.new(action_handler_callable).call(env)
  end

  def call_without_middleware(env)
    @env = env

    # First try to route via actions...
    given_http_method = env.fetch('REQUEST_METHOD')
    given_path = env.fetch('PATH_INFO')
    given_path = '/' + given_path unless given_path.start_with?('/')

    action_list = self.class.actions
    # TODO: I believe Sinatra matches bottom-up, not top-down.
    action_list.reverse.each do | (action_http_method, action_url_path, action_options, action_handler_callable)|
      route_pattern = Mustermann.new(action_url_path)
      if given_http_method == action_http_method && route_params = route_pattern.params(given_path)
        @request = Rack::Request.new(env)
        @params.merge!(@request.params)
        @route_params = route_params

        match = route_pattern.match(given_path)
        @route_params['captures'] = match.captures unless match.nil?
        @params.merge!(@route_params)
        return perform_action_block(&action_handler_callable)
      end
    end

    # and if nothing works out - respond with a 404
    out = JSON.pretty_generate({
      error: 'No matching action found for %s %s' % [given_http_method, given_path],
    })
    [404, {'Content-Type' => 'application/json', 'Content-Length' => out.bytesize.to_s}, [out]]
  end

  def self.call(env)
    app = new
    Rack::Builder.new do
      (@middleware_configurations || []).each do |middleware_args|
        use(*middleware_args)
      end
      run ->(env) { app.call_without_middleware(env) }
    end.to_app.call(env)
  end

  attr_reader :request
  attr_reader :env
  attr_reader :params

  def initialize
    @status = 200
    @content_type = 'text/plain'
    @params = Apiculture::IndifferentHash.new
  end

  def content_type(new_type)
    @content_type = Rack::Mime.mime_type('.%s' % new_type)
  end

  def route_params
    @env['apiculture.route_params']
  end

  def status(status_code)
    @status = status_code.to_i
  end

  def halt(rack_status, rack_headers, rack_body)
    throw :halt, [rack_status, rack_headers, rack_body]
  end

  def perform_action_block(&blk)
    # Execut the action in a Sinatra-like fashion - passing the route parameter values as
    # arguments to the given block/callable. This is where in the future we should ditch
    # the Sinatra calling conventions - Sinatra mandates that the action accept the route parameters
    # as arguments and grab all the useful stuff from instance methods like `params` etc. whereas
    # we probably want to have just Rack apps mounted per route (under an action)
    response = catch(:halt) do
      body_string_or_rack_triplet = instance_exec(*@route_params.values, &blk)

      if rack_triplet?(body_string_or_rack_triplet)
        return body_string_or_rack_triplet
      end

     [@status, {'Content-Type' => @content_type}, [body_string_or_rack_triplet]]
    end

    return response
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
