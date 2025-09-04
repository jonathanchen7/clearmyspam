# == Schema Information
#
# Table name: users
#
#  id                      :uuid             not null, primary key
#  admin                   :boolean          default(FALSE)
#  email                   :string           not null
#  google_refresh_token    :string
#  image                   :string
#  last_login_at           :datetime         not null
#  name                    :string           not null
#  onboarding_completed_at :datetime
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  vendor_id               :string           not null
#
# Indexes
#
#  index_users_on_vendor_id  (vendor_id) UNIQUE
#
class User < ApplicationRecord
  devise :omniauthable, omniauth_providers: [:google_oauth2]

  has_many :account_plans, autosave: true
  has_one :active_account_plan, -> { order(created_at: :desc) }, class_name: "AccountPlan"
  has_one :option, autosave: true
  has_one :metrics
  has_many :email_tasks
  has_many :pending_email_disposals
  has_many :protected_emails
  has_many :protected_senders
  attribute :google_access_token, :string
  attribute :google_access_token_expires_at, :datetime

  delegate :active_pro?, :inactive_pro?, :unpaid?, to: :active_account_plan

  validates :email, uniqueness: true

  after_create :send_welcome_email

  class GoogleRefreshTokenMissingError < StandardError; end

  class << self
    def from_omniauth(auth)
      current_time = Time.now
      user = where(vendor_id: auth.uid).first_or_create do |user|
        user.vendor_id = auth.uid
        user.email = auth.info.email
        user.name = auth.info.name
        user.image = auth.info.image
        user.created_at = current_time

        user.account_plans.build(
          plan_type: "trial",
          thread_disposal_limit: AccountPlan::DEFAULT_THREAD_DISPOSAL_LIMIT
        )
        user.option = Option.new(unread_only: true)
        user.metrics = Metrics.new(
          initial_total_threads: 0,
          initial_unread_threads: 0,
          total_threads: 0,
          unread_threads: 0
        )
      end
      user.google_refresh_token = auth.credentials.refresh_token if auth.credentials.refresh_token.present?
      user.last_login_at = current_time

      user.save!

      user
    end
  end

  def google_auth_expired?
    google_access_token_expires_at.nil? || google_access_token_expires_at < Time.now
  end

  def refresh_google_auth!(force: false, session: nil)
    return unless force || google_auth_expired?

    Rails.logger.info("Refreshing Google access token for user: #{id}".on_blue)

    response = oauth_client.fetch_access_token!
    update(
      google_access_token: response["access_token"],
      google_access_token_expires_at: Time.now + response["expires_in"]
    )

    if session.present?
      session[:google_access_token] = google_access_token
      session[:google_access_token_expires_at] = google_access_token_expires_at
    end
  end

  def disable_dispose?
    if active_pro?
      false
    elsif inactive_pro?
      true
    elsif unpaid?
      metrics.disposed_count >= active_account_plan.thread_disposal_limit
    else
      true
    end
  end

  def remaining_disposal_count
    if active_pro?
      nil
    elsif unpaid?
      [active_account_plan.thread_disposal_limit - metrics.disposed_count, 0].max
    else
      0
    end
  end

  def onboarding_completed?
    onboarding_completed_at.present?
  end

  def to_honeybadger_context
    { user_id: id, user_email: email }
  end

  def gmail_client
    @gmail_client ||= Gmail::Client.new(self)
  end

  def brand_new?
    created_at == last_login_at
  end

  private

  def oauth_client
    Signet::OAuth2::Client.new(
      token_credential_uri: "https://oauth2.googleapis.com/token",
      client_id: Rails.application.credentials.dig(:google, :client_id),
      client_secret: Rails.application.credentials.dig(:google, :client_secret),
      refresh_token: google_refresh_token
    )
  end

  def send_welcome_email
    UserMailer.with(user: self).welcome.deliver_later
  end
end
