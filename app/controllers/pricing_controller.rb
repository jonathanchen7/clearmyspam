require "stripe"

class PricingController < ApplicationController
  set_rate_limit to: 5, only: [:checkout, :billing_portal]

  before_action :authenticate_user!, only: [:checkout, :billing_portal]
  before_action :set_stripe_api_key, only: [:checkout, :billing_portal]

  def index
  end

  def checkout
    plan_type = params.require(:type)

    raise "User is already on pro plan" if current_user.active_pro?

    session = Stripe::Checkout::Session.create(
      {
        line_items: [
          {
            price: AccountPlan.stripe_price_id_for(plan_type),
            quantity: 1
          }
        ],
        success_url: app_url,
        cancel_url: app_url,
        mode: "subscription",
        automatic_tax: { enabled: true },
        allow_promotion_codes: true,
        customer_email: current_user.email
      }
    )

    render json: { success: true, url: session.url }
  end

  def billing_portal
    if current_user.active_account_plan.stripe_customer_id.blank?
      raise "No Stripe customer is associated with current user"
    end

    session = Stripe::BillingPortal::Session.create(
      {
        customer: current_user.active_account_plan.stripe_customer_id,
        return_url: app_url
      }
    )

    render json: { success: true, url: session.url }
  end

  private

  def set_stripe_api_key
    Stripe.api_key = Rails.application.credentials.dig(:stripe, :api_key)
  end
end
