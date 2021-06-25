require_relative '../spec_helper'

describe 'Apiculture.api_documentation' do
  let!(:test_class) do
    class PancakeApi < Apiculture::App
      extend Apiculture

      documentation_build_time!

      desc 'Order a pancake'
      required_param :diameter, 'Diameter of the pancake. The pancake will be **bold**', Integer
      param :topping, 'Type of topping', String
      pancake_response_info = <<~EOS
        When the pancake has been baked successfully
        The pancake will have the following properties:

        * It is going to be round
        * It is going to be delicious
      EOS
      responds_with 200, pancake_response_info, { id: 'abdef..c21' }
      api_method :post, '/pancakes' do
      end

      desc 'Check the pancake status'
      route_param :id, 'Pancake ID to check status on'
      responds_with 200, 'When the pancake is found', { status: 'Baking' }
      responds_with 404, 'When no such pancake exists', { status: 'No such pancake' }
      api_method :get, '/pancake/:id' do
      end

      desc 'Throw away the pancake'
      route_param :id, 'Pancake ID to delete'
      api_method :delete, '/pancake/:id' do
      end

      desc 'Pancake ingredients are in the URL'
      route_param :topping_id, 'Pancake topping ID', Integer, cast: :to_i
      api_method :get, '/pancake/with/:topping_id' do |topping_id|
      end
    end
  end

  let(:documentation) { PancakeApi.api_documentation }
  let(:open_api_map) { documentation.to_openapi.spec }

  describe '.to_openapi' do
    it 'will have openapi version' do
      expect(open_api_map).to include(openapi: '3.0.0')
    end

    describe 'info' do
      let(:info) { open_api_map.fetch(:info) }

      it 'will not to be empty' do
        expect(info).not_to be_empty
      end

      it 'will have title' do
        expect(info).to include(title: 'PancakeApi')
      end

      it 'will have version' do
        expect(info).to include(version: '0.0.1')
      end

      it 'will have description' do
        expect(info).to include(:description)
        expect(info[:description]).to include('PancakeApi Documentation built on')
      end
    end

    describe 'paths' do
      let(:paths) { open_api_map.fetch(:paths) }

      it 'will have paths' do
        expect(paths).not_to be_empty
      end

      it 'will have 4 paths' do
        expect(paths.size).to eq(3)
      end

      context 'POST /pancakes' do
        let(:post_pancakes) { paths.dig('/pancakes', :post) }

        it 'will have route' do
          expect(post_pancakes).not_to be_empty
        end

        describe 'request body content' do
          let(:request_content) { post_pancakes.dig(:requestBody, :content) }
          it 'will have correct JSON content type' do
            expect(request_content).to have_key(:'application/json')
          end

          describe 'schema' do
            let(:schema) { request_content.dig(:'application/json', :schema) }
            it 'will have type' do
              expect(schema).to include(type: :object)
            end

            it 'will have required parameters' do
              expect(schema).to include(required: [:diameter])
            end

            describe 'properties' do
              let(:properties) { schema.fetch(:properties) }
              it 'will have all properties' do
                expect(properties).to have_key :diameter
                expect(properties).to have_key :topping
              end
            end
          end
        end
      end

      context 'GET /pancake/:id' do
        let(:get_pancake_by_id_path) { paths.dig('/pancake/{id}', :get) }
        it 'will have route' do
          expect(get_pancake_by_id_path).not_to be_empty
        end

        it 'will have summary' do
          expect(get_pancake_by_id_path).to include(summary: 'Check the pancake status')
        end

        it 'will have a description' do
          expect(get_pancake_by_id_path).to include(description: 'Check the pancake status')
        end

        it 'will have operationId' do
          expect(get_pancake_by_id_path).to have_key :operationId
        end

        describe 'parameters' do
          let(:parameter) { get_pancake_by_id_path.fetch(:parameters).first }

          it 'will contain parameter' do
            expect(parameter).not_to be_empty
          end

          it 'will have required propertie' do
            expect(parameter).to include(required: true)
          end

          it 'will indicate a path parameter' do
            expect(parameter).to include(in: :path)
          end

          describe 'schema' do
            let(:schema) { parameter.fetch(:schema) }
            it 'will have object type' do
              expect(schema).to include(type: 'string')
            end

            it 'will have an example' do
              expect(schema).to include(example: 'string')
            end
          end
        end

        describe 'responses' do
          let(:responses) { get_pancake_by_id_path.fetch(:responses) }

          it 'will contain all responses by response code' do
            expect(responses).to have_key('200')
            expect(responses).to have_key('404')
          end

          describe 'response 200' do
            let(:response_200) { responses.fetch('200') }

            it 'will have description' do
              expect(response_200).to include(description: 'When the pancake is found')
            end

            it 'will have correct content type' do
              expect(response_200.fetch(:content)).to have_key(:'application/json')
            end

            describe 'schema' do
              let(:schema) { response_200.dig(:content, :'application/json', :schema) }
              
              it 'will have object type' do
                expect(schema).to include(type: 'object')
              end

              it 'will have properties' do
                expect(schema).to have_key :properties
              end
            end
          end
        end
      end
    end
  end
end
