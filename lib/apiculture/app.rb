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
    # First try to route via actions...
    given_http_method = env.fetch('REQUEST_METHOD')
    given_path = env.fetch('PATH_INFO')
    given_path = '/' + given_path unless given_path.start_with?('/')

    action_list = self.class.actions
    # TODO: I believe Sinatra matches bottom-up, not top-down.
    action_list.each do | (action_http_method, action_url_path, action_options, action_handler_callable)|
      route_pattern = Mustermann.new(action_url_path)
      if given_http_method == action_http_method && route_params = route_pattern.params(given_path)
        return perform_action_with_handler_block(env, route_params, action_handler_callable)
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

end
