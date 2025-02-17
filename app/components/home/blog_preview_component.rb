module Home
  class BlogPreviewComponent < ViewComponent::Base
    def initialize(title:, subtitle:, tag:, slug:)
      @title = title
      @subtitle = subtitle
      @tag = tag
      @slug = slug
    end
  end
end
