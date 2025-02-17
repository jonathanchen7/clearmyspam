# frozen_string_literal: true

module Home
  class ReviewComponent < ViewComponent::Base
    def initialize(text:, author:, socials: nil)
      @text = text
      @author = author
      @socials = socials
    end
  end
end
