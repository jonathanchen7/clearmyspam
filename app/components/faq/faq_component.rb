# frozen_string_literal: true

module FAQ
  class FAQComponent < ViewComponent::Base
    def initialize(question:, answer:)
      @question = question
      @answer = answer
    end
  end
end
