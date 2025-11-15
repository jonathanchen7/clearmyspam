# == Schema Information
#
# Table name: account_plans
#
#  id                           :uuid             not null, primary key
#  daily_disposal_limit         :integer
#  plan_type                    :string           not null
#  stripe_subscription_ended_at :datetime
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  stripe_customer_id           :string
#  stripe_subscription_id       :string
#  user_id                      :uuid             not null
#
# Indexes
#
#  index_account_plans_on_user_id  (user_id)
#
class AccountPlan < ApplicationRecord
  PRO_PLAN_TYPES = %w[weekly monthly yearly].freeze
  FREE_PLAN_TYPES = %w[trial].freeze

  MONTHLY_PRICE_ID = Rails.application.credentials.dig(:stripe, :monthly_price_id)
  WEEKLY_PRICE_ID = Rails.application.credentials.dig(:stripe, :weekly_price_id)
  YEARLY_PRICE_ID = Rails.application.credentials.dig(:stripe, :yearly_price_id)

  TRIAL_DAILY_DISPOSAL_LIMIT = Rails.configuration.trial_daily_disposal_limit

  belongs_to :user

  validates :plan_type, inclusion: { in: PRO_PLAN_TYPES + FREE_PLAN_TYPES }
  validates :daily_disposal_limit, presence: true, if: -> { unpaid? }
  validates :stripe_subscription_id, :stripe_customer_id, presence: true, if: -> { pro? }
  validate :no_active_pro_plans, on: :create

  class << self
    def stripe_price_id_for(type)
      case type
      when "weekly"
        WEEKLY_PRICE_ID
      when "monthly"
        MONTHLY_PRICE_ID
      when "yearly"
        YEARLY_PRICE_ID
      else
        raise "Invalid plan type"
      end
    end

    def plan_type_for(price_id)
      case price_id
      when WEEKLY_PRICE_ID
        "weekly"
      when MONTHLY_PRICE_ID
        "monthly"
      when YEARLY_PRICE_ID
        "yearly"
      else
        raise "Invalid price ID"
      end
    end
  end

  def end_subscription!(at: Time.current)
    raise "Free or non-active pro plans cannot be ended" unless active_pro?

    update!(stripe_subscription_ended_at: at)
  end

  def active_pro?
    pro? && stripe_subscription_ended_at.nil?
  end

  def inactive_pro?
    pro? && stripe_subscription_ended_at.present?
  end

  def unpaid?
    FREE_PLAN_TYPES.include?(plan_type)
  end

  private

  def pro?
    PRO_PLAN_TYPES.include?(plan_type)
  end

  def no_active_pro_plans
    errors.add(:user, "already has an active pro plan") if user.account_plans.any? { |plan| plan.active_pro? }
  end
end
