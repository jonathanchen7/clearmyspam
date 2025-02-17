class TabsComponent < ViewComponent::Base
  def initialize(tabs, current_tab_id:, base_path:)
    @tabs = tabs
    @current_tab_id = current_tab_id
    @base_path = base_path
  end
end
