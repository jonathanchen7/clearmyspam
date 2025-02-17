require "faker"

FactoryBot.define do
  factory :user do
    id { SecureRandom.uuid }
    email { Faker::Internet.email }
    name { Faker::Name.name }
    vendor_id { Faker::Alphanumeric.alphanumeric(number: 10) }
  end
end
