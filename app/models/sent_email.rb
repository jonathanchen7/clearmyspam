require "stripe"

# == Schema Information
#
# Table name: sent_emails
#
#  id            :uuid             not null, primary key
#  email_type    :string           not null
#  metadata_json :jsonb            not null
#  sent_at       :datetime         not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  user_id       :uuid             not null
#
# Indexes
#
#  index_sent_emails_on_user_id                 (user_id)
#  index_sent_emails_on_user_id_and_email_type  (user_id,email_type) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
class SentEmail < ApplicationRecord
  belongs_to :user

  VALID_EMAIL_TYPES = [
    "welcome",
    "re_engagement",
    "re_engagement_reminder"
  ].freeze

  validates :email_type, presence: true, uniqueness: { scope: :user_id }, inclusion: { in: VALID_EMAIL_TYPES }

  RE_ENGAGEMENT_COUPON_DISCOUNT_DOLLARS = 5
  RE_ENGAGEMENT_COUPON_EXPIRY_DAYS = 7

  class << self
    def send_re_engagement_email!(user, discount_code: nil)
      ApplicationRecord.transaction do
        discount_code ||= generate_stripe_coupon!(user)

        UserMailer.with(user: user, discount_code:).re_engagement.deliver_later
        user.sent_emails.create!(email_type: "re_engagement", metadata_json: { discount_code: })
      end
    end

    def send_re_engagement_reminder_email!(user)
      return unless (re_engagement_email = user.sent_emails.find_by(email_type: "re_engagement"))

      ApplicationRecord.transaction do
        discount_code = re_engagement_email.metadata_json["discount_code"]

        UserMailer.with(user: user, discount_code:).re_engagement_reminder.deliver_later
        user.sent_emails.create!(email_type: "re_engagement_reminder", metadata_json: re_engagement_email.metadata_json)
      end
    end

    private

    def generate_stripe_coupon!(user)
      Stripe.api_key = Rails.application.credentials.dig(:stripe, :api_key)
      coupon = Stripe::Coupon.create(
        currency: "USD",
        amount_off: RE_ENGAGEMENT_COUPON_DISCOUNT_DOLLARS * 100,
        duration: "once",
        name: "thanks for the feedback! :)",
        redeem_by: RE_ENGAGEMENT_COUPON_EXPIRY_DAYS.days.from_now.to_i,
        metadata: {
          user_id: user.id,
          user_email: user.email
        }
      )

      coupon.id
    end
  end
end
