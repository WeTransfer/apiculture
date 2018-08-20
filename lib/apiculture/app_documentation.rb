require_relative 'method_documentation'
require_relative 'tagged_markdown'

class Apiculture::AppDocumentation
  JOINER = "\n\n"
  TEMPLATE_PATH = '/app_documentation_tpl.mustache'
  
  def initialize(app, mountpoint, action_definitions_and_markdown_segments)
    @app_title = app.to_s
    @mountpoint = mountpoint
    @chunks = action_definitions_and_markdown_segments
  end
  
  # Generates a Markdown string that contains the entire API documentation
  def to_markdown
    (['## %s' % @app_title] + to_tagged_markdowns).join(JOINER)
  end

  # Generates a complete HTML document string that can be saved into a file
  def to_html
    require 'mustache'
    template = File.read(__dir__ + TEMPLATE_PATH)
    Mustache.render(template, html_fragment: to_html_fragment)
  end
  
  # Generates an HTML fragment string that can be included into another HTML document
  def to_html_fragment
    to_tagged_markdowns.map(&:to_html).join(JOINER)
  end

  private
  
    def to_tagged_markdowns
      @chunks.map do |action_def_or_doc|
        action_def_or_doc.to_tagged_markdown(@mountpoint)
      end
    end
end
