# frozen_string_literal: true

module Home
  class FeatureComponent < ViewComponent::Base
    def initialize(title:, icon:, description: nil)
      @title = title
      @description = description
      @icon = icon
    end
  end
end
