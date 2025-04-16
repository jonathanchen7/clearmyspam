FactoryBot.define do
  factory :metrics do
    user
    initial_total_threads { 0 }
    initial_unread_threads { 0 }
    total_threads { 0 }
    unread_threads { 0 }
    trashed_count { 0 }
    archived_count { 0 }
  end
end
