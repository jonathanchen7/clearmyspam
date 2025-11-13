require "faker"

FactoryBot.define do
  factory :email do
    transient do
      sender { build(:sender) }
      date { Date.current }
    end

    vendor_id { SecureRandom.hex(16) }
    subject { Faker::Lorem.sentence }
    snippet { Faker::Lorem.paragraph }
    label_ids { ["INBOX"] }
    protected { false }

    trait :unread do
      label_ids { ["INBOX", "UNREAD"] }
    end

    trait :protected do
      protected { true }
    end

    trait :old do
      date { 1.year.ago }
    end

    trait :recent do
      date { 1.day.ago }
    end

    initialize_with do
      new(
        vendor_id: vendor_id,
        sender:,
        date: date,
        subject: subject,
        snippet: snippet,
        label_ids: label_ids
      )
    end
  end
end
