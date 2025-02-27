# == Schema Information
#
# Table name: blogs
#
#  id           :uuid             not null, primary key
#  published_at :datetime         not null
#  slug         :string           not null
#  subtitle     :string           not null
#  tag          :string           not null
#  title        :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_blogs_on_slug  (slug) UNIQUE
#
require "redcarpet"

class Blog < ApplicationRecord
  validates :slug, presence: true, uniqueness: true
  validates :title, :published_at, presence: true

  delegate :markdown_renderer, to: :class

  scope :recent, ->(limit = 6) { order(published_at: :desc).limit(limit) }

  class << self
    def markdown_renderer
      Redcarpet::Markdown.new(Blogs::MarkdownRenderer, autolink: true, tables: true)
    end

    def find_by_slug!(slug)
      find_by!(slug: slug)
    end
  end

  def path
    Rails.application.routes.url_helpers.blogs_show_path(slug: slug)
  end

  def render
    markdown_renderer.render(content).html_safe
  end

  private

  def markdown_file
    Rails.root.join("app/views/blogs/#{slug}.md")
  end

  def content
    return "" unless File.exist?(markdown_file)
    markdown_file.read
  end
end
