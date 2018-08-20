require 'github/markup'

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