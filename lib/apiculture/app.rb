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

    def define_action(http_method, url_path, **options, &handler_blk)
      @actions ||= []
      @actions << [http_method, url_path, options, handler_blk]
    end
  end

  def call_without_middleware(env)
    # First try to route via actions...
    path = env['PATH_INFO'].to_s
    path = '/' + path unless path.start_with?('/')

    # and if nothing works out - respond with a 404
    out = JSON.pretty_generate({
      error: 'No matching action found for path %s' % env['PATH_INFO'],
    })
    [404, {'Content-Type' => 'application/json', 'Content-Length' => out.bytesize.to_s}, [out]]
  end

  def self.transform_params(env)
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
