class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  attr_reader :on_dashboard, :toast, :pixel_client

  before_action :set_honeybadger_context
  before_action :initialize_toast
  before_action :initialize_pixel_client

  class << self
    def set_rate_limit(to:, only: nil)
      rate_limit to: to, only: only, within: 1.minute, by: -> { current_user.id }, unless: -> { Rails.env.development? }
    end
  end

  def set_honeybadger_context
    Honeybadger.context(current_user) if current_user.present?
  end

  def initialize_toast
    @toast = ToastComponent.new
  end

  def initialize_pixel_client
    @pixel_client = Facebook::PixelClient.from_request(current_user, request) if current_user.present?
  end
end
