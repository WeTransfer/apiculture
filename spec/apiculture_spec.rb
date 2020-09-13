require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Apiculture" do
  include Rack::Test::Methods

  before(:each) { @app_class = nil }
  def app
    @app_class or raise "No @app_class defined in the example"
  end

  context 'as API definition DSL' do
    it 'allows all the standard Siantra DSL to go through without modifications' do
      @app_class = Class.new(Apiculture::App) do
        extend Apiculture

        post '/things/*' do
          params.inspect
        end
      end

      post '/things/a/b/c/d', {'foo' => 'bar'}
      expect(last_response.body).to eq("{\"foo\"=>\"bar\", \"splat\"=>[\"a/b/c/d\"], \"captures\"=>[\"a/b/c/d\"]}")
    end

    it 'flags :captures as a reserved Sinatra parameter when used as a URL param' do
      expect {
        Class.new(Apiculture::App) do
          extend Apiculture
          route_param :captures, "Something it captures"
          api_method(:get, '/thing/:captures') { raise "Should never be called" }
        end
      }.to raise_error(/\:captures is a reserved magic parameter name/)
    end

    it 'flags :captures as a reserved Sinatra parameter when used as a request param' do
      expect {
        Class.new(Apiculture::App) do
          extend Apiculture
          param :captures, "Something it captures", String
          api_method(:get, '/thing') { raise "Should never be called" }
        end
      }.to raise_error(/\:captures is a reserved magic parameter name/)
    end

    it 'flags :splat as a reserved Sinatra parameter when used as a URL param' do
      expect {
        Class.new(Apiculture::App) do
          extend Apiculture
          route_param :splat, "Something it splats"
          api_method(:get, '/thing/:splat') { raise "Should never be called" }
        end
      }.to raise_error(/\:splat is a reserved magic parameter name/)
    end

    it 'flags :splat as a reserved Sinatra parameter when used as a request param' do
      expect {
        Class.new(Apiculture::App) do
          extend Apiculture
          param :splat, "Something it splats", String
          api_method(:get, '/thing') { raise "Should never be called" }
        end
      }.to raise_error(/\:splat is a reserved magic parameter name/)
    end

    it 'flags URL and request params of the same name' do
      expect {
        Class.new(Apiculture::App) do
          extend Apiculture
          route_param :id, 'Id of the thing'
          param :id, "Something it identifies (conflict)", String
          api_method(:get, '/thing/:id') { raise "Should never be called" }
        end
      }.to raise_error(/\:id mentioned twice/)
    end

    it "defines a basic API that can be called" do
      $created_thing = nil
      @app_class = Class.new(Apiculture::App) do
        extend Apiculture

        desc "Create a Thing with a name"
        route_param :id, "The ID of the thing"
        required_param :name, "Name of the thing", String
        api_method :post, '/thing/:id' do | thing_id |
          $created_thing = {id: thing_id, name: params[:name]}
          'Wild success'
        end
      end

      post '/thing/123', {name: 'Monsieur Thing'}
      expect(last_response.body).to eq('Wild success')
      expect($created_thing).to eq({id: '123', name: 'Monsieur Thing'})
    end

    it "serves the API documentation at a given URL using serve_api_documentation_at" do
      $created_thing = nil
      @app_class = Class.new(Apiculture::App) do
        extend Apiculture

        desc "Create a Thing with a name"
        required_param :name, "Name of the thing", String
        api_method( :post, '/thing/:id') {}
        serve_api_documentation_at('/documentation')
      end

      get '/documentation'
      expect(last_response['Content-Type']).to include('text/html')
      expect(last_response.body).to include('Create a Thing')
    end

    it 'raises when a required param is not provided' do
      @app_class = Class.new(Apiculture::App) do
        extend Apiculture

        required_param :name, "Name of the thing", String
        api_method :post, '/thing' do
          raise "Should never be called"
        end
      end

      expect {
        post '/thing', {}
      }.to raise_error('Missing parameter :name')
    end

    it 'verifies the parameter type and allows addition of middleware' do
      require 'rack/parser'
      @app_class = Class.new(Apiculture::App) do
        extend Apiculture
        use Rack::Parser

        required_param :number, "Number of the thing", Integer
        api_method :post, '/thing' do
          raise "Did end up in the action"
        end
      end

      expect {
        post '/thing', JSON.dump({number: '123'}), {'CONTENT_TYPE' => 'application/json'}
      }.to raise_error('Received String, expected Integer for :number')

      expect {
        post '/thing', JSON.dump({number: 123}), {'CONTENT_TYPE' => 'application/json'}
      }.to raise_error(/Did end up in the action/)
    end

    it 'allows addition of middleware' do
      class Raiser < Struct.new(:app)
        def call(env)
          s, h, b = app.call(env)
          h['X-Via'] = 'Raiser'
          [s, h, b]
        end
      end

      @app_class = Class.new(Apiculture::App) do
        extend Apiculture
        use Raiser

        api_method :post, '/thing' do
          'Everything is fine'
        end
      end

      post '/thing'

      raise last_response.headers.inspect
    end

    it 'supports an arbitrary object with === as a type specifier for a parameter' do
      custom_matcher = Class.new do
        def ===(value)
          value == "Magic word"
        end
      end.new

      @app_class = Class.new(Apiculture::App) do
        extend Apiculture

        required_param :pretty_please, "Only a magic word will do", custom_matcher
        api_method :post, '/thing' do
          'Ohai!'
        end
      end

      post '/thing', {pretty_please: 'Magic word'}
      expect(last_response).to be_ok

      expect {
        post '/thing', {pretty_please: 'not the magic word you are looking for'}
      }.to raise_error(Apiculture::ParameterTypeMismatch)
    end

    it 'suppresses parameters that are not defined in the action definition' do
      @app_class = Class.new(Apiculture::App) do
        extend Apiculture

        api_method :post, '/thing' do
          raise ":evil_ssh_injection should have wiped from params{}" if params[:evil_ssh_injection]
          'All is well'
        end
      end

      post '/thing', {evil_ssh_injection: 'I am Homakov!'}
      expect(last_response).to be_ok
    end

    it 'allows route parameters that are not mentioned in the action definition, but are given in Sinatra path' do
      @app_class = Class.new(Apiculture::App) do
        extend Apiculture

        api_method :post, '/api-thing/:id_of_thing' do |id|
          raise 'id_of_thing must be passed' unless id == '123456'
          raise "id_of_thing must be present in params, but they were #{params.inspect}" unless params.keys.include?('id_of_thing')
          raise "id_of_thing must be string-accessible in params" unless params['id_of_thing'] == '123456'
          raise "id_of_thing must be symbol-accessible in params" unless params[:id_of_thing] == '123456'
          'All is well'
        end

        post '/vanilla-thing/:id_of_thing' do |id|
          raise 'id_of_thing must be passed' unless id == '123456'
          raise "id_of_thing must be present in params, but they were #{params.inspect}" unless params.keys.include?('id_of_thing')
          raise "id_of_thing must be string-accessible in params" unless params['id_of_thing'] == '123456'
          raise "id_of_thing must be symbol-accessible in params" unless params[:id_of_thing] == '123456'
          'All is well'
        end
      end

      post '/vanilla-thing/123456'
      expect(last_response).to be_ok

      post '/api-thing/123456'
      expect(last_response).to be_ok
    end

    it 'does not clobber the status set in a separate mutating call when using json_response' do
      @app_class = Class.new(Apiculture::App) do
        extend Apiculture

        api_method :post, '/api/:id' do
          status 201
          json_response({was_created: true})
        end
      end

      post '/api/123'
      expect(last_response.status).to eq(201)
    end

    it 'raises when describing a route parameter that is not included in the path' do
      expect {
        Class.new(Apiculture::App) do
          extend Apiculture
          route_param :thing_id, "The ID of the thing"
          api_method(:get, '/thing/:id') { raise "Should never be called" }
        end
      }.to raise_error('Parameter :thing_id not present in path "/thing/:id"')
    end

    it 'returns a 404 when a non existing route is called' do
      @app_class = Class.new(Apiculture::App) do
        extend Apiculture

        api_method :post, '/api' do
          [1]
        end
      end

      post '/api-404'
      expect(last_response.status).to eq(404)
    end

    it 'applies a symbol typecast by calling a method on the parameter value' do
      @app_class = Class.new(Apiculture::App) do
        extend Apiculture

        required_param :number, "Number of the thing", Integer, :cast => :to_i
        api_method :post, '/thing' do
          raise "Not cast" unless params[:number] == 123
          'Total success'
        end
      end
      post '/thing', {number: '123'}
      expect(last_response.body).to eq('Total success')
    end

    it 'ensures current behaviour for route params is not changed' do
      @app_class = Class.new(Apiculture::App) do
        extend Apiculture

        route_param :number, "Number of the thing"
        api_method :post, '/thing/:number' do
          raise "Casted to int" if params[:number] == 123
          'Total success'
        end
      end
      post '/thing/123'
      expect(last_response.body).to eq('Total success')
    end

    it 'supports returning a rack triplet' do
      @app_class = Class.new(Apiculture::App) do
        extend Apiculture
        api_method :get, '/rack' do
          [402, {'X-Money-In-The-Bank' => 'yes, please'}, ['Buy bitcoin']]
        end
      end
      get '/rack'
      expect(last_response.status).to eq 402
      expect(last_response.body).to eq 'Buy bitcoin'
    end

    it 'ensures current behaviour when no route params are present does not change' do
      @app_class = Class.new(Apiculture::App) do
        extend Apiculture

        param :number, "Number of the thing", Integer, cast: :to_i
        api_method :post, '/thing' do
          raise "Behaviour changed" unless params[:number] == 123
          'Total success'
        end
      end
      post '/thing', {number: '123'}
      expect(last_response.body).to eq('Total success')
    end

    it 'applies a symbol typecast by calling a method on the route parameter value' do
      @app_class = Class.new(Apiculture::App) do
        extend Apiculture

        route_param :number, "Number of the thing", Integer, :cast => :to_i
        api_method :post, '/thing/:number' do
          raise "Not cast" unless params[:number] == 123
          'Total success'
        end
      end
      post '/thing/123'
      expect(last_response.body).to eq('Total success')
    end


    it 'cast block arguments to the right type', run: true do
      @app_class = Class.new(Apiculture::App) do
        extend Apiculture

        route_param :number, "Number of the thing", Integer, :cast => :to_i
        api_method :post, '/thing/:number' do |number|
          raise "Not cast" unless number.is_a?(Integer)
          'Total success'
        end
      end
      post '/thing/123'
      expect(last_response.body).to eq('Total success')

      # Double checking that bignums are okay, too
      bignum = 10**30
      post "/thing/#{bignum}"
      expect(last_response.body).to eq('Total success')
    end


    it 'merges route_params and regular params' do
      @app_class = Class.new(Apiculture::App) do
        extend Apiculture

        param :number, "Number of the thing", Integer, :cast => :to_i
        route_param :id, "Id of the thingy", Integer, :cast => :to_i
        route_param :awesome, "Hash of the thingy"

        api_method :post, '/thing/:id/:awesome' do |id|
          raise 'Not merged' unless params.has_key?("id")
          raise 'Not merged' unless params.has_key?("awesome")
          'Thanks'
        end
      end
      post '/thing/1/true', {number: '123'}
      expect(last_response.body).to eq('Thanks')
    end


    it 'applies a Proc typecast by calling the proc (for example - for ISO8601 time)' do
      @app_class = Class.new(Apiculture::App) do
        extend Apiculture

        required_param :when, "When it happened", Time, cast: ->(v){ Time.parse(v) }
        api_method :post, '/occurrence' do
          raise "Not cast" unless params[:when].year == 2015
          raise "Not cast" unless params[:when].month == 7
          'Total success'
        end
      end
      post '/occurrence', {when: '2015-07-05T22:16:18Z'}
      expect(last_response.body).to eq('Total success')
    end
  end

  context 'Sinatra instance method extensions' do
    it 'adds support for json_response' do
      @app_class = Class.new(Apiculture::App) do
        extend Apiculture
        api_method :get, '/some-json' do
          json_response({foo: 'bar'})
        end
      end

      get '/some-json'
      expect(last_response).to be_ok
      expect(last_response['Content-Type']).to include('application/json')
      parsed_body = JSON.load(last_response.body)
      expect(parsed_body['foo']).to eq('bar')
    end

    it 'adds support for json_response to set http status code', run: true do
      @app_class = Class.new(Apiculture::App) do
        extend Apiculture
        api_method :post, '/some-json' do
          json_response({foo: 'bar'}, status: 201)
        end
      end

      post '/some-json'
      expect(last_response.status).to eq(201)
    end

    it 'adds support for json_halt' do
      @app_class = Class.new(Apiculture::App) do
        extend Apiculture
        api_method :get, '/simple-halt' do
          json_halt "Nein."
          raise "This should never be called"
        end
        api_method :get, '/halt-with-custom-status' do
          json_halt 'Nein.', status: 503
          raise "This should never be called"
        end
        api_method :get, '/halt-with-error-payload' do
          json_halt 'Nein.', teapot: true
          raise "This should never be called"
        end
      end

      get '/simple-halt'
      expect(last_response.status).to eq(400)
      expect(last_response['Content-Type']).to include('application/json')
      parsed_body = JSON.load(last_response.body)
      expect(parsed_body).to eq({"error"=>"Nein."})

      get '/halt-with-error-payload'
      expect(last_response.status).to eq(400)
      expect(last_response['Content-Type']).to include('application/json')
      parsed_body = JSON.load(last_response.body)
      expect(parsed_body).to eq({"error"=>"Nein.", "teapot"=>true})
    end

    # Mocks didn't play well with setting the status in a sinatra action
    class NilTestAction < Apiculture::Action
      def perform
        status 204
        nil
      end
    end
    it 'allows returning an empty body when the status is 204' do
      @app_class = Class.new(Apiculture::App) do
        extend Apiculture
        api_method :get, '/nil204' do
          action_result NilTestAction
        end
      end

      get '/nil204'
      expect(last_response.status).to eq(204)
      expect(last_response.body).to be_empty
    end

    it "does not allow returning an empty body when the status isn't 204" do
      # Mock out the perform call so that status doesn't change from the default of 200
      expect_any_instance_of(NilTestAction).to receive(:perform).with(any_args).and_return(nil)
      @app_class = Class.new(Apiculture::App) do
        extend Apiculture
        api_method :get, '/nil200' do
          action_result NilTestAction
        end
      end

      expect{
        get '/nil200'
      }.to raise_error(RuntimeError)
    end
  end
end
