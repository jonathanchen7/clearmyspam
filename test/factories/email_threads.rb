require "faker"

FactoryBot.define do
  factory :email_thread do
    id { SecureRandom.uuid }
    vendor_id { Faker::Alphanumeric.alphanumeric(number: 10) }
    user
    protected { false }
    trashed { false }
    archived { false }

    sender { build(:sender) }
    subject { Faker::Lorem.sentence }
    date { DateTime.now }
    snippet { Faker::Lorem.paragraph }
    label_ids { %w[INBOX] }

    trait :unread do
      label_ids { %w[UNREAD INBOX] }
    end

    trait :protected do
      protected { true }
    end
  end
end
