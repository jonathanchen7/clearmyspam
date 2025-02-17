class FloatingBannerComponent < ViewComponent::Base
  def initialize(cta_text:, cta_stimulus_data:)
    @cta_text = cta_text
    @cta_stimulus_data = cta_stimulus_data
  end
end
