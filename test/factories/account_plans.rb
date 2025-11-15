require "faker"

FactoryBot.define do
  factory :account_plan do
    id { SecureRandom.uuid }
    user { create(:user) }

    trait :pro do
      plan_type { "monthly" }
      stripe_customer_id { Faker::Alphanumeric.alphanumeric(number: 10) }
      stripe_subscription_id { Faker::Alphanumeric.alphanumeric(number: 10) }
    end

    trait :free do
      plan_type { "trial" }
      daily_disposal_limit { 500 }
      stripe_customer_id { nil }
      stripe_subscription_id { nil }
    end
  end
end
