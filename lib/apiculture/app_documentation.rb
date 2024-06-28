require_relative 'method_documentation'
require 'github/markup'

class Apiculture::AppDocumentation
  class TaggedMarkdown < Struct.new(:string, :section_class)
    def to_markdown
      string.to_markdown.to_s rescue string.to_s
    end

    def to_html
      '<section class="%s">%s</section>' % [Rack::Utils.escape_html(section_class), render_markdown(to_markdown)]
    end

    def render_markdown(s)
      GitHub::Markup.render('section.markdown', s.to_s)
    end
  end

  def initialize(app, mountpoint, action_definitions_and_markdown_segments)
    @app_title = app.to_s
    @mountpoint = mountpoint
    @chunks = action_definitions_and_markdown_segments
  end

  # Generates a Markdown string that contains the entire API documentation
  def to_markdown
    (['## %s' % @app_title] + to_markdown_slices).join("\n\n")
  end

  def to_openapi
    OpenApiDocumentation::Base.new(@app_title, @mountpoint, @chunks)
  end

  # Generates an HTML fragment string that can be included into another HTML document
  def to_html_fragment
    to_markdown_slices.map do |tagged_markdown|
      tagged_markdown.to_html
    end.join("\n\n")
  end

  def to_markdown_slices
    markdown_slices = @chunks.map do | action_def_or_doc |
      if action_def_or_doc.respond_to?(:http_verb) # ActionDefinition
        s = Apiculture::MethodDocumentation.new(action_def_or_doc, @mountpoint).to_markdown
        TaggedMarkdown.new(s, 'apiculture-method')
      elsif action_def_or_doc.respond_to?(:to_markdown)
        TaggedMarkdown.new(action_def_or_doc, 'apiculture-verbatim')
      end
    end
  end

  # Generates a complete HTML document string that can be saved into a file
  def to_html
    require 'mustache'
    template = File.read(__dir__ + '/app_documentation_tpl.mustache')
    Mustache.render(template, :html_fragment => to_html_fragment)
  end
end
