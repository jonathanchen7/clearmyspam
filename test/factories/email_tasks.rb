FactoryBot.define do
  factory :email_task do
    user
    vendor_id { Faker::Alphanumeric.alphanumeric(number: 10) }
    attempts { 0 }

    trait :archive do
      type { "archive" }
      payload { nil }
    end

    trait :trash do
      type { "trash" }
      payload { nil }
    end

    trait :move do
      type { "move" }
      payload { { "label_id" => Faker::Alphanumeric.alphanumeric(number: 8) } }
    end

    trait :with_attempts do
      attempts { rand(1..5) }
    end
  end
end
