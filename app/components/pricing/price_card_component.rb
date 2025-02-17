# frozen_string_literal: true

module Pricing
  class PriceCardComponent < ViewComponent::Base
    def initialize(name:, subtitle:, price:, term:, features:, cta:, plan_type:, tag: nil, featured: false)
      @name = name
      @tag = tag
      @subtitle = subtitle
      @price = price
      @term = term
      @features = features
      @cta = cta
      @plan_type = plan_type
      @featured = featured
    end
  end
end
