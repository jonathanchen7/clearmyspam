# == Schema Information
#
# Table name: protected_emails
#
#  id         :uuid             not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :uuid             not null
#  vendor_id  :string           not null
#
# Indexes
#
#  index_protected_emails_on_user_id_and_vendor_id  (user_id,vendor_id) UNIQUE
#
class ProtectedEmail < ApplicationRecord
  belongs_to :user

  class << self
    def protected_emails(user, vendor_ids)
      where(user: user, vendor_id: vendor_ids).pluck(:vendor_id)
    end
  end
end
