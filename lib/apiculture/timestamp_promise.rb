class Apiculture::TimestampPromise
  def self.to_markdown
    ts = Time.now.utc.strftime "%Y-%m-%d %H:%M"
    "Documentation built on #{ts}"
  end
end
