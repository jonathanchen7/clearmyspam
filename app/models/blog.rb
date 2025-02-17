require "redcarpet"

class Blog
  attr_reader :slug

  delegate :markdown_renderer, to: :class

  class << self
    def markdown_renderer
      Redcarpet::Markdown.new(Blogs::MarkdownRenderer, autolink: true, tables: true)
    end
  end

  def initialize(slug)
    @slug = slug

    raise ArgumentError, "Blog does not exist" unless File.exist?(markdown_file)
  end

  def render
    markdown_renderer.render(content).html_safe
  end

  private

  def markdown_file
    Rails.root.join("app/views/blogs/#{slug}.md")
  end

  def content
    markdown_file.read
  end
end
