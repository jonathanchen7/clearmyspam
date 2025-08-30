FactoryBot.define do
  factory :option do
    user
    archive { false }
    hide_personal { false }
    unread_only { true }
  end
end
