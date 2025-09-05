# frozen_string_literal: true

class Admin::TabsComponent < ViewComponent::Base
  def initialize(active_tab: "usage", metrics: nil)
    @active_tab = active_tab
    @metrics = metrics
  end

  private

  attr_reader :active_tab, :metrics

  def tabs
    [
      {
        id: "usage",
        label: "Usage Analytics",
        icon: "fas fa-trash-alt",
        description: "Email disposal and usage metrics"
      },
      {
        id: "signups",
        label: "Sign-ups Analytics",
        icon: "fas fa-user-plus",
        description: "User registration and onboarding"
      },
      {
        id: "logins",
        label: "Login Analytics",
        icon: "fas fa-sign-in-alt",
        description: "User activity and engagement"
      }
    ]
  end

  def tab_classes(tab_id)
    base_classes = "flex items-center px-6 py-3 text-sm font-medium rounded-t-lg border-b-2 transition-colors duration-200"

    if active_tab == tab_id
      "#{base_classes} text-indigo-600 border-indigo-600 bg-indigo-50"
    else
      "#{base_classes} text-gray-500 border-transparent hover:text-gray-700 hover:border-gray-300"
    end
  end
end
