class IconButtonComponent < ViewComponent::Base
  def initialize(icon:, color:, disabled: false, path: nil, tooltip: "", stimulus_data: nil)
    @icon = icon
    @color = color
    @disabled = disabled
    @path = path
    @tooltip = tooltip
    @stimulus_data = stimulus_data
  end

  def icon_tag
    icon("fa-solid", @icon, class: @color)
  end
end
