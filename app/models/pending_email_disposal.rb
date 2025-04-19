# == Schema Information
#
# Table name: pending_email_disposals
#
#  id         :uuid             not null, primary key
#  archive    :boolean          not null
#  created_at :datetime         not null
#  user_id    :uuid             not null
#  vendor_id  :string           not null
#
# Indexes
#
#  index_pending_email_disposals_on_user_id_and_created_at  (user_id,created_at)
#  index_pending_email_disposals_on_user_id_and_vendor_id   (user_id,vendor_id) UNIQUE
#

class PendingEmailDisposal < ApplicationRecord
  belongs_to :user

  class << self
    def insert_attributes(user, vendor_ids)
      archive = user.option.archive
      vendor_ids.map { |vendor_id| { user_id: user.id, vendor_id: vendor_id, archive: archive } }
    end
  end
end
