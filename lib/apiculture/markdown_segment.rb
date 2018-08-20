# Just a tiny String container for literal documentation chunks
class Apiculture::MarkdownSegment < Struct.new(:string)
  def to_markdown
    string.to_s
  end

  def to_tagged_markdown(_mountpoint)
    TaggedMarkdown.new(self, 'apiculture-verbatim')
  end
end
