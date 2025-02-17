# frozen_string_literal: true

module FAQ
  class FAQComponent < ViewComponent::Base
    def initialize(question:, answer: nil)
      @question = question
      @answer = answer
    end
  end
end
