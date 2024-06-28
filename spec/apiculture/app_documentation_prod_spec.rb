require_relative '../spec_helper'

describe "Apiculture.api_documentation in prod environments" do
  let(:app) do
    Class.new(Apiculture::App) do
      extend Apiculture

      set_environment "production"

      markdown_string 'This API is very important. Because it has to do with pancakes.'

      documentation_build_time!

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

  it 'does not generate any html in non-dev environments' do
    docco = app.api_documentation
    generated_html = docco.to_html_fragment

    expect(generated_html).to eq("")
  end

  # It still generates some small bits of Markdown but not a lot
  it 'does not generate app documentation in Markdown' do
    docco = app.api_documentation
    generated_markdown = docco.to_markdown

    expect(generated_markdown.length).to eq(30)
  end
end
