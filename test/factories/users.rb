require "faker"

FactoryBot.define do
  factory :user do
    id { SecureRandom.uuid }
    email { Faker::Internet.email }
    name { Faker::Name.name }
    vendor_id { Faker::Alphanumeric.alphanumeric(number: 10) }
    last_login_at { Time.now }
    send_marketing_emails { true }

    after(:create) do |user|
      create(:account_plan, :free, user: user)
      create(:metrics, user: user)
      create(:option, user: user)
    end

    trait :with_re_engagement_email do
      after(:create) do |user|
        user.sent_emails.create!(email_type: "re_engagement", metadata_json: {})
      end
    end

    trait :with_re_engagement_reminder_email do
      after(:create) do |user|
        user.sent_emails.create!(email_type: "re_engagement_reminder", metadata_json: {})
      end
    end
  end
end
