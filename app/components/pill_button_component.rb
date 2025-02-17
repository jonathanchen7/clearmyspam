class PillButtonComponent < ViewComponent::Base
  def initialize(type: "primary", path: nil, stimulus_data: nil, disabled: false)
    raise "Either path or stimulus_data must be provided" if path.nil? && stimulus_data.nil?

    @type = type
    @path = path
    @stimulus_data = stimulus_data
    @disabled = disabled
  end

  def button_styles
    case @type
    when DashboardHelper::ButtonTypes::PRIMARY
      "bg-primary text-white"
    when DashboardHelper::ButtonTypes::SECONDARY
      "bg-white text-black ring-1 ring-gray-300"
    when DashboardHelper::ButtonTypes::DANGER
      "bg-danger text-white"
    when DashboardHelper::ButtonTypes::TEXT
      "text-primary bg-white hover:enabled:backdrop-brightness-75"
    else
      raise "Invalid button type"
    end
  end
end
