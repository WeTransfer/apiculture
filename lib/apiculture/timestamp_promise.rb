class Apiculture::TimestampPromise
  def self.to_markdown
    ts = Time.now.utc.strftime "%Y-%m-%d %H:%M"
    "Documentation built on #{ts}"
  end

  def self.to_tagged_markdown(_mountpoint)
    TaggedMarkdown.new(self, 'apiculture-verbatim')
  end
end
