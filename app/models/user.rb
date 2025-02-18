# == Schema Information
#
# Table name: users
#
#  id                      :uuid             not null, primary key
#  email                   :string           not null
#  google_refresh_token    :string
#  image                   :string
#  last_logged_in_at       :datetime
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
  has_many :email_threads

  attribute :google_access_token, :string
  attribute :google_access_token_expires_at, :datetime

  delegate :active_pro?, :inactive_pro?, :unpaid?, to: :active_account_plan

  validates :email, uniqueness: true

  class << self
    def from_omniauth(auth)
      user = where(vendor_id: auth.uid).first_or_create do |user|
        user.vendor_id = auth.uid
        user.email = auth.info.email
        user.name = auth.info.name
        user.image = auth.info.image

        user.account_plans.build(
          plan_type: "trial",
          thread_disposal_limit: AccountPlan::DEFAULT_THREAD_DISPOSAL_LIMIT
        )
        user.option = Option.new(unread_only: true)
      end
      user.google_refresh_token = auth.credentials.refresh_token if auth.credentials.refresh_token.present?
      user.last_logged_in_at = Time.now

      user.save!

      user
    end
  end

  def google_auth_expired?
    google_access_token_expires_at.nil? || google_access_token_expires_at < Time.now
  end

  def refresh_google_auth!(session: nil)
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
      email_threads.disposed.count >= active_account_plan.thread_disposal_limit
    else
      true
    end
  end

  def remaining_disposal_count
    if active_pro?
      nil
    elsif unpaid?
      [active_account_plan.thread_disposal_limit - email_threads.disposed.count, 0].max
    else
      0
    end
  end

  def admin?
    email == "jonathanchen.dev@gmail.com"
  end

  def onboarding_completed?
    onboarding_completed_at.present?
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
end
