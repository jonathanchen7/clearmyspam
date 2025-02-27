# frozen_string_literal: true

module Home
  class BlogPreviewComponent < ViewComponent::Base
    attr_reader :blog

    def initialize(blog)
      @blog = blog
    end

    def formatted_date
      blog.published_at.strftime("%B %d, %Y")
    end
  end
end
