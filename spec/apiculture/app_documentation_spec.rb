require_relative '../spec_helper'

describe "Apiculture.api_documentation" do
  let(:app) {
    Class.new(Sinatra::Base) do
      extend Apiculture
      
      markdown_string 'This API is very important. Because it has to do with pancakes.'
      
      documentation_build_time!
      
      desc 'Order a pancake'
      required_param :diameter, "Diameter of the pancake", Integer
      param :topping, 'Type of topping', String
      responds_with 200, 'When the pancake is created succesfully', {id: 'abdef..c21'}
      api_method :post, '/pancakes' do
      end
      
      desc 'Check the pancake status'
      route_param :id, 'Pancake ID to check status on'
      responds_with 200, 'When the pancake is found', {status: 'Baking'}
      responds_with 404, 'When no such pancake exists', {status: 'No such pancake'}
      api_method :get, '/pancake/:id' do
      end
      
      desc 'Throw away the pancake'
      route_param :id, 'Pancake ID to delete'
      api_method :delete, '/pancake/:id' do
      end
    end
  }
  
  it 'generates app documentation as HTML without the body element' do
    docco = app.api_documentation
    generated_html = docco.to_html_fragment
    
    expect(generated_html).not_to include('<body')
    expect(generated_html).to include('Pancake ID to check status on')
    expect(generated_html).to include('Pancake ID to delete')
  end
  
  it 'generates app documentation in HTML' do
    docco = app.api_documentation
    generated_html = docco.to_html
    
    if ENV['SHOW_TEST_DOC']
      File.open('t.html', 'w') do |f|
        f.write(generated_html)
        f.flush
        `open #{f.path}`
      end
    end
   
    expect(generated_html).to include('<body')
    expect(generated_html).to include('Pancake ID to check status on')
    expect(generated_html).to include('When the pancake is created succesfully')
    expect(generated_html).to include('"id": "abdef..c21"')
  end
  
  it 'generates app documentation in Markdown' do
    docco = app.api_documentation
    generated_markdown = docco.to_markdown
    
    expect(generated_markdown).not_to include('<body')
    expect(generated_markdown).to include('## POST /pancakes')
  end
  
  it 'generates app documentation honoring the mount point' do
    overridden = Class.new(Sinatra::Base) do
      extend Apiculture
      mounted_at '/api/v2/'
      api_method :get, '/pancakes' do
      end
    end
    
    generated_markdown = overridden.api_documentation.to_markdown
    expect(generated_markdown).to include('## GET /api/v2/pancakes')
  end
  
  it 'generates app documentation injecting the inline Markdown strings' do
    app_class = Class.new(Sinatra::Base) do
      extend Apiculture
      markdown_string '# This describes important stuff'
      api_method :get, '/pancakes' do
      end
      markdown_string '# This describes even more important stuff'
      markdown_string 'This is a paragraph'
    end
    
    generated_html = app_class.api_documentation.to_html
    expect(generated_html).to include('<h2>GET /pancakes</h2>')
    expect(generated_html).to include('<h1>This describes even more important stuff')
    expect(generated_html).to include('<h1>This describes important stuff')
    expect(generated_html).to include('<p>This is a paragraph')
  end
  
  context 'with a file containing Markdown that has to be spliced into the docs' do
    before(:each) { File.open('./TEST.md', 'w') {|f| f << "# This is an important header"} }
    after(:each) { File.unlink('./TEST.md') }
    it 'splices the contents of the file using markdown_file' do
      app_class = Class.new(Sinatra::Base) do
        extend Apiculture
        markdown_file './TEST.md'
        api_method :get, '/pancakes' do
        end
      end
    
      generated_html = app_class.api_documentation.to_html
      expect(generated_html).to include('<h2>GET /pancakes</h2>')
      expect(generated_html).to include('<h1>This is an important header')
    end
  end
end
