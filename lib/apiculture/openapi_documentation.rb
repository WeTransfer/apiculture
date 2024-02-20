# frozen_string_literal: true
require 'yaml'
require 'base64'
module OpenApiDocumentation
  class Base
    def initialize(app, prefix, chunks)
      @app, @prefix = app, prefix
      @paths = chunks.select { |chunk| chunk.respond_to?(:http_verb) }
      @data = {
        openapi: '3.0.0',
        info: {
          title: @app.to_s,
          version: '0.0.1',
          description: @app.to_s + " " + chunks.select { |chunk| chunk.respond_to?(:to_markdown) }.map(&:to_markdown).join("\n")
        },
        tags: []
      }
      @data[:paths] = build_paths
    end

    def to_yaml
      JSON.load(@data.to_json).to_yaml # trickery to get string based yaml
    end

    def paths
      @data[:paths]
    end

    def spec
      @data
    end

    private

    def build_paths
      paths = {}
      @paths.each do |path|
        path = Path.new(path, @prefix, @app)
        paths = merge_paths(paths, path)
      end
      paths
    end

    # We don't have deep_merge here so this is the poor man's alternative
    def merge_paths(paths, path)
      if paths.key?(path.name)
        paths[path.name].merge!(path.build[path.name])
      else
        paths.merge!(path.build)
      end
      paths
    end

  end

  class Path
    VERBS_WITHOUT_BODY = %w(get head delete options)

    def initialize(path, prefix, app)
      @path, @prefix, @app = path, prefix, app
    end

    def build
      request_body = build_request_body unless VERBS_WITHOUT_BODY.include?(@path.http_verb)
      {
        name =>
        {
          @path.http_verb.to_sym => {
            summary: @path.description,
            description: @path.description,
            tags: [ @app.to_s ],
            parameters: build_parameters,
            requestBody: request_body,
            responses: build_responses,
            operationId: operation_id
          }.delete_if { |_k, v| v.nil? || v.empty? }
        }
      }
    end

    def name
      full_path = @path.path.to_s
      @path.route_parameters.each do |parameter|
        # This is a bit confusing but naming is a little different between
        # apiculture and openapi
        full_path = full_path.gsub(":#{parameter.name}", "\{#{parameter.name}\}")
      end
      Util.clean_path("#{@prefix}#{full_path}")
    end

    private

    def operation_id
      # base64 encoding to make sure these ids are safe to use in an url
      Base64.urlsafe_encode64("#{@path.http_verb}#{@prefix}#{@path.path}")
    end

    def build_parameters
      if VERBS_WITHOUT_BODY.include?(@path.http_verb)
        build_route_parameters + build_query_parameters
      else
        build_route_parameters
      end
    end

    def build_route_parameters
      route_params = @path.route_parameters.map do |parameter|
        {
          name: parameter.name,
          description: parameter.description,
          required: true,
          in: :path,
          schema: {
            type: Util.map_type(parameter.matchable),
            example: Util.map_example(parameter.matchable)
          }
        }
      end
      route_params
    end

    def build_query_parameters
      params = @path.parameters.map do |parameter|
        {
          name: parameter.name,
          description: parameter.description,
          required: true,
          in: :query,
          schema: {
            type: Util.map_type(parameter.matchable),
            example: parameter.matchable
          }
        }
      end
      params
    end

    def build_request_body
      return nil if VERBS_WITHOUT_BODY.include?(@path.http_verb)

      body_params = Hash[ @path.parameters.collect do |parameter|
        [parameter.name, {
          type: Util.map_type(parameter.matchable),
          description: parameter.description
        }]
      end ]

      return nil if body_params.count == 0

      schema = {
        type: :object,
        properties: body_params
      }

      schema[:required] = @path.parameters.select(&:required).map(&:name) if @path.parameters.select(&:required).map(&:name).count > 0
      {
        content: {
          "application/json": {
            schema: schema
          }
        }
      }
    end

    def build_responses
      responses = Hash[@path.responses.collect do |response|
        _response = {
          description: response.description
        }

        unless response.jsonable_object_example.nil? || response.jsonable_object_example.empty?
          _response[:content] = {
            'application/json': {
                schema:
                  { type: 'object',
                  properties: Util.response_to_schema(response.jsonable_object_example) }
            }
          }
        end

        [response.http_status_code.to_s, _response]
      end ]
      responses
    end
  end

  class Util
    TYPES = {
      String => 'string',
      Integer => 'integer',
      TrueClass => 'boolean'
    }.freeze

    EXAMPLES = {
      String => 'string',
      Integer => 1234,
      TrueClass => true
    }.freeze

    def self.response_to_schema(response)
      case response
      when NilClass
      when String
        { type: 'string', example: response }
      when Integer
        { type: 'integer', example: response }
      when Float
        { type: 'float', example: response }
      when Array
        if response.empty?
          { type: 'array', items: {} }
        else
          { type: 'array', items: response.map { |elem| response_to_schema(elem) } }
        end
      when Hash
        response.each_with_object({}) do |(key, val), schema_hash|
          schema_hash[key] = response_to_schema(val)
        end
      else
        { type: response.class.name.downcase, example: response.to_s }
      end
    end

    def self.map_type(type)
      TYPES.fetch(type, 'string')
    end

    def self.map_example(type)
      EXAMPLES.fetch(type, 'string')
    end

    def self.clean_path(path)
      path.gsub(/\/\?\*\?$/, '')
    end
  end
end
