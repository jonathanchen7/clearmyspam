# == Schema Information
#
# Table name: protected_senders
#
#  id         :uuid             not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  sender_id  :string           not null
#  user_id    :uuid             not null
#
# Indexes
#
#  index_protected_senders_on_sender_id_and_user_id  (sender_id,user_id) UNIQUE
#
class ProtectedSender < ApplicationRecord
  belongs_to :user

  class << self
    def actionable_sender_ids(user, sender_ids)
      protected_sender_ids = where(user: user, sender_id: sender_ids).pluck(:sender_id)
      sender_ids - protected_sender_ids
    end
  end
end
