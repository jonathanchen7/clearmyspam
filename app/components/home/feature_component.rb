# frozen_string_literal: true

module Home
  class FeatureComponent < ViewComponent::Base
    def initialize(title:, description:, icon:)
      @title = title
      @description = description
      @icon = icon
    end
  end
end
