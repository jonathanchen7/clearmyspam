require "faker"

FactoryBot.define do
  factory :user do
    id { SecureRandom.uuid }
    email { Faker::Internet.email }
    name { Faker::Name.name }
    vendor_id { Faker::Alphanumeric.alphanumeric(number: 10) }
    last_login_at { Time.now }

    after(:create) do |user|
      create(:account_plan, :free, user: user)
      create(:metrics, user: user)
    end
  end
end
