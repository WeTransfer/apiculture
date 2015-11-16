require_relative '../spec_helper'
require_relative '../../lib/apiculture/method_documentation'

describe Apiculture::MethodDocumentation do
  it 'generates HTML from an ActionDefinition with path, verb and both route and request params' do
    definition = Apiculture::ActionDefinition.new
    
    definition.description = "This action bakes pancakes"
    definition.parameters << Apiculture::Parameter.new(:name, 'Pancake name', true, String, :to_s)
    definition.parameters << Apiculture::Parameter.new(:thickness, 'Pancake thickness', false, Float, :to_f)
    definition.parameters << Apiculture::Parameter.new(:diameter, 'Pancake diameter', false, Integer, :to_i)
    
    definition.route_parameters << Apiculture::RouteParameter.new(:pan_id, 'ID of the pancake frying pan')
    definition.http_verb = 'get'
    definition.path = '/pancake/:pan_id/bake'
    
    documenter = described_class.new(definition)
    
    generated_html = documenter.to_html_fragment
    generated_markdown = documenter.to_markdown
    
    expect(generated_html).not_to include('<body>')
    
    expect(generated_html).to include('<h2>GET /pancake/:pan_id/bake</h2>')
    expect(generated_html).to include('<p>This action bakes pancakes</p>')
    expect(generated_html).to include('<h3>URL parameters</h3>')
    expect(generated_html).to include('ID of the pancake frying pan')
    expect(generated_html).to include('<h3>Request parameters</h3>')
    expect(generated_html).to include('<td>Pancake name</td>')
  end
  
  it 'generates HTML from an ActionDefinition without route params' do
    definition = Apiculture::ActionDefinition.new
    
    definition.description = "This action bakes pancakes"
    definition.parameters << Apiculture::Parameter.new(:name, 'Pancake name', true, String, :to_s)
    definition.parameters << Apiculture::Parameter.new(:thickness, 'Pancake thickness', false, Float, :to_f)
    definition.parameters << Apiculture::Parameter.new(:diameter, 'Pancake diameter', false, Integer, :to_i)
    
    definition.http_verb = 'get'
    definition.path = '/pancake'
    
    documenter = described_class.new(definition)
    generated_html = documenter.to_html_fragment
    
    expect(generated_html).not_to include('<h3>URL parameters</h3>')
  end
  
  it 'generates HTML from an ActionDefinition without request params' do
    definition = Apiculture::ActionDefinition.new
    
    definition.description = "This action bakes pancakes"
    
    definition.route_parameters << Apiculture::RouteParameter.new(:pan_id, 'ID of the pancake frying pan')
    definition.http_verb = 'get'
    definition.path = '/pancake/:pan_id/bake'
    
    documenter = described_class.new(definition)
    
    generated_html = documenter.to_html_fragment
    generated_markdown = documenter.to_markdown
    
    expect(generated_html).not_to include('<h3>Request parameters</h3>')
  end
  
  it 'generates Markdown from an ActionDefinition with a mountpoint' do
    definition = Apiculture::ActionDefinition.new
    
    definition.description = "This action bakes pancakes"
    
    definition.route_parameters << Apiculture::RouteParameter.new(:pan_id, 'ID of the pancake frying pan')
    definition.http_verb = 'get'
    definition.path = '/pancake/:pan_id/bake'
    
    documenter = described_class.new(definition, '/api/v1')
    
    generated_markdown = documenter.to_markdown
    expect(generated_markdown).to include('## GET /api/v1/pancake/:pan_id')
  end
end
