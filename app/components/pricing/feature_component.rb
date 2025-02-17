# frozen_string_literal: true

module Pricing
  class FeatureComponent < ViewComponent::Base
    def initialize(feature)
      @feature = feature
    end
  end
end
