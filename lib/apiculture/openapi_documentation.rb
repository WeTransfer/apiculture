# frozen_string_literal: true

require 'yaml'
module OpenApiDocumentation
  class Base
    def initialize(app, chunks)
      @app = app
      @endpoints = chunks.select { |chunk| chunk.respond_to?(:http_verb) }
      @data = {
        swagger: '2.0',
        info: { title: @app.to_s, version: '0.0.1' }
      }
      build
    end

    def build
      @data[:paths] = build_endpoints
    end

    def build_endpoints
      endpoints = {}
      @endpoints.each do |endpoint|
        endpoint = Endpoint.new(endpoint)
        endpoints = merge_endpoints(endpoints, endpoint)
      end
      endpoints
    end

    # We don't have deep_merge here so this is the poor man's alternative
    def merge_endpoints(endpoints, endpoint)
      if endpoints.key?(endpoint.path)
        endpoints[endpoint.path].merge!(endpoint.build[endpoint.path])
      else
        endpoints.merge!(endpoint.build)
      end
      endpoints
    end

    def to_yaml
      JSON.load(@data.to_json).to_yaml # trickery to get string based yaml
    end
  end

  class Endpoint
    TYPES = {
      String => 'string',
      Integer => 'integer'
    }.freeze

    def initialize(endpoint)
      @endpoint = endpoint
    end

    def path
      @endpoint.route_parameters.each do |parameter|
        @endpoint.path.to_s.gsub!(":#{parameter.name}", "\{#{parameter.name}\}")
      end
      @endpoint.path.to_s
    end

    def build
      {
        path =>
        {
          @endpoint.http_verb.to_sym => {
            description: @endpoint.description,
            parameters: build_parameters,
            responses: build_responses
          }.delete_if { |_k, v| v.empty? }
        }
      }
    end

    def build_parameters
      body_params = Hash[ @endpoint.parameters.collect do |parameter|
        [parameter.name, {
          type: Endpoint.map_type(parameter.matchable),
          description: parameter.description
        }]
      end ]

      params = @endpoint.route_parameters.map do |parameter|
        {
          name: parameter.name,
          description: parameter.description,
          required: true,
          in: :path,
          type: Endpoint.map_type(parameter.matchable)
        }
      end

      if body_params.count >= 1
        body_param = {
          name: :body,
          required: true,
          in: :body,
          schema: {
            type: :object,
            properties: body_params,
            required: @endpoint.parameters.select(&:required).map(&:name)
          }
        }
        params << body_param
      end
      params
    end

    def build_responses
      responses = Hash[@endpoint.responses.collect do |response|
        [response.http_status_code.to_s, {
          description: response.description,
          schema: {
            type: :string,
            example: response.jsonable_object_example
          }
        }]
      end ]
      if responses.empty?
        responses['200'] = { description: 'No response defined' } # Set a default response to please swagger
      end
      responses
    end

    def self.map_type(type)
      TYPES.fetch(type, 'string')
    end
  end
end
