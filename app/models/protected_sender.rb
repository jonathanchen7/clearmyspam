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
end
