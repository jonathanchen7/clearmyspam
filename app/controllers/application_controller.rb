class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  attr_reader :hide_header_navigation, :toast

  before_action :initialize_toast

  def initialize_toast
    @toast = ToastComponent.new
  end
end
