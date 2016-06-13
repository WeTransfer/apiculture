require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Apiculture" do
  include Rack::Test::Methods
  
  before(:each) { @app_class = nil }
  def app
    @app_class or raise "No @app_class defined in the example"
  end
  
  context 'as API definition DSL' do
    it 'allows all the standard Siantra DSL to go through without modifications' do
      @app_class = Class.new(Sinatra::Base) do
        settings.show_exceptions = false
        settings.raise_errors = true
        extend Apiculture
      
        post '/things/*' do
          return params.inspect
        end
      end
      
      post '/things/a/b/c/d', {'foo' => 'bar'}
      expect(last_response.body).to eq("{\"foo\"=>\"bar\", \"splat\"=>[\"a/b/c/d\"], \"captures\"=>[\"a/b/c/d\"]}")
    end
    
    it 'flags :captures as a reserved Sinatra parameter when used as a URL param' do
      expect {
        Class.new(Sinatra::Base) do
          extend Apiculture
          route_param :captures, "Something it captures"
          api_method(:get, '/thing/:captures') { raise "Should never be called" }
        end
      }.to raise_error(/\:captures is a reserved magic parameter name/)
    end
    
    it 'flags :captures as a reserved Sinatra parameter when used as a request param' do
      expect {
        Class.new(Sinatra::Base) do
          extend Apiculture
          param :captures, "Something it captures", String
          api_method(:get, '/thing') { raise "Should never be called" }
        end
      }.to raise_error(/\:captures is a reserved magic parameter name/)
    end
    
    it 'flags :splat as a reserved Sinatra parameter when used as a URL param' do
      expect {
        Class.new(Sinatra::Base) do
          extend Apiculture
          route_param :splat, "Something it splats"
          api_method(:get, '/thing/:splat') { raise "Should never be called" }
        end
      }.to raise_error(/\:splat is a reserved magic parameter name/)
    end
    
    it 'flags :splat as a reserved Sinatra parameter when used as a request param' do
      expect {
        Class.new(Sinatra::Base) do
          extend Apiculture
          param :splat, "Something it splats", String
          api_method(:get, '/thing') { raise "Should never be called" }
        end
      }.to raise_error(/\:splat is a reserved magic parameter name/)
    end
    
    it 'flags URL and request params of the same name' do
      expect {
        Class.new(Sinatra::Base) do
          extend Apiculture
          route_param :id, 'Id of the thing'
          param :id, "Something it identifies (conflict)", String
          api_method(:get, '/thing/:id') { raise "Should never be called" }
        end
      }.to raise_error(/\:id mentioned twice/)
    end
    
    it "defines a basic API that can be called" do
      $created_thing = nil
      @app_class = Class.new(Sinatra::Base) do
        settings.show_exceptions = false
        settings.raise_errors = true
      
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
      @app_class = Class.new(Sinatra::Base) do
        settings.show_exceptions = false
        settings.raise_errors = true
      
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
      @app_class = Class.new(Sinatra::Base) do
        settings.show_exceptions = false
        settings.raise_errors = true
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
  
    it 'verifies the parameter type' do
      @app_class = Class.new(Sinatra::Base) do
        settings.show_exceptions = false
        settings.raise_errors = true
        extend Apiculture
      
        required_param :number, "Number of the thing", Integer
        api_method :post, '/thing' do
          raise "Should never be called"
        end
      end
    
      expect {
        post '/thing', {number: '123'}
      }.to raise_error('Received String, expected Integer for :number')
    end
    
    it 'suppresses parameters that are not defined in the action definition' do
      @app_class = Class.new(Sinatra::Base) do
        settings.show_exceptions = false
        settings.raise_errors = true
        extend Apiculture
      
        api_method :post, '/thing' do
          raise ":evil_ssh_injection should have wiped from params{}" if params[:evil_ssh_injection]
          'All is well'
        end
      end
      
      post '/thing', {evil_ssh_injection: 'I am Homakov!'}
      expect(last_response).to be_ok
    end
    
    it 'raises when describing a route parameter that is not included in the path' do
      expect {
        Class.new(Sinatra::Base) do
          extend Apiculture
          route_param :thing_id, "The ID of the thing"
          api_method(:get, '/thing/:id') { raise "Should never be called" }
        end
      }.to raise_error('Parameter :thing_id not present in path "/thing/:id"')
    end
    
    it 'applies a symbol typecast by calling a method on the parameter value' do
      @app_class = Class.new(Sinatra::Base) do
        settings.show_exceptions = false
        settings.raise_errors = true
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
      @app_class = Class.new(Sinatra::Base) do
        settings.show_exceptions = false
        settings.raise_errors = true
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

    it 'ensures current behaviour when no route params are present does not change' do
      @app_class = Class.new(Sinatra::Base) do
        settings.show_exceptions = false
        settings.raise_errors = true
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
      @app_class = Class.new(Sinatra::Base) do
        settings.show_exceptions = false
        settings.raise_errors = true
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


    it 'cast block arguments to the right type' do
      @app_class = Class.new(Sinatra::Base) do
        settings.show_exceptions = false
        settings.raise_errors = true
        extend Apiculture
      
        route_param :number, "Number of the thing", Fixnum, :cast => :to_i
        api_method :post, '/thing/:number' do |number|
          raise "Not cast" unless number.class == Fixnum
          'Total success'
        end
      end
      post '/thing/123'
      expect(last_response.body).to eq('Total success')
    end

    
    it 'merges route_params and regular params' do
      @app_class = Class.new(Sinatra::Base) do
        settings.show_exceptions = false
        settings.raise_errors = true
        extend Apiculture
      
        param :number, "Number of the thing", Integer, :cast => :to_i
        route_param :id, "Id of the thingy", Fixnum, :cast => :to_i
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
      @app_class = Class.new(Sinatra::Base) do
        settings.show_exceptions = false
        settings.raise_errors = true
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

    it 'captures route parameters when using regex url' do
      @app_class = Class.new(Sinatra::Base) do
        settings.show_exceptions = false
        settings.raise_errors = true
        extend Apiculture
    
        route_param :id, 'Id of the thing'

        api_method :get, /^\/occurrence\/(?<id>\w+)$/ do |id|
          raise "Not parsed" unless params[:id] == 'yoloswag'
          raise "Not parsed" unless id == 'yoloswag'
          'Total success'
        end
      end
      get '/occurrence/yoloswag'
      expect(last_response.body).to eq('Total success')
    end
  end
  
  context 'Sinatra instance method extensions' do
    it 'adds support for json_response' do
      @app_class = Class.new(Sinatra::Base) do
        extend Apiculture
        settings.show_exceptions = false
        settings.raise_errors = true
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
    it 'adds support for json_response to set http status code' do
      @app_class = Class.new(Sinatra::Base) do
        extend Apiculture
        settings.show_exceptions = false
        settings.raise_errors = true
        api_method :post, '/some-json' do
          json_response({foo: 'bar'}, status: 201)
        end
      end
      
      post '/some-json'
      expect(last_response.status).to eq(201)
    end
    it 'adds support for json_halt' do
      @app_class = Class.new(Sinatra::Base) do
        extend Apiculture
        settings.show_exceptions = false
        settings.raise_errors = true
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
  end
end
