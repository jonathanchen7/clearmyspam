require "stripe"

class WebhooksController < ApplicationController
  protect_from_forgery with: :null_session

  before_action :set_stripe_api_key, only: [:stripe]

  def stripe
    event_type = params.require(:type)
    stripe_object = params.require(:data).require(:object)

    case event_type
    when "checkout.session.completed"
      checkout_session_completed(stripe_object)
    when "customer.subscription.deleted"
      customer_subscription_deleted(stripe_object)
    else
      raise "Unsupported event type #{event_type}"
    end
  end

  private

  def checkout_session_completed(stripe_object)
    subscription_id = stripe_object.require(:subscription)
    customer_id = stripe_object.require(:customer)

    customer = Stripe::Customer.retrieve(customer_id)
    raise "Provided customer is deleted" if customer.deleted?

    user = User.find_by!(email: customer.email)
    price_id = Stripe::Subscription.retrieve(subscription_id).items.data.first.price.id

    unless user.active_pro?
      user.account_plans.create!(
        stripe_subscription_id: subscription_id,
        stripe_customer_id: customer_id,
        plan_type: AccountPlan.plan_type_for(price_id)
      )
    end

    render json: { success: true, user_id: user.id }
  end

  def customer_subscription_deleted(stripe_object)
    subscription_id = stripe_object.require(:id)
    subscription_ended_at = Time.at(stripe_object.require(:ended_at))

    account_plan = AccountPlan.find_by!(stripe_subscription_id: subscription_id)
    unless account_plan.stripe_subscription_ended_at.present?
      account_plan.end_subscription!(at: subscription_ended_at)
    end

    render json: { success: true, user_id: account_plan.user_id }
  end

  def set_stripe_api_key
    Stripe.api_key = Rails.application.credentials.dig(:stripe, :api_key)
  end
end
