# == Schema Information
#
# Table name: pending_email_disposals
#
#  id              :uuid             not null, primary key
#  archive         :boolean          not null
#  created_at      :datetime         not null
#  email_thread_id :uuid
#  user_id         :uuid             not null
#  vendor_id       :string           not null
#
# Indexes
#
#  index_pending_email_disposals_on_user_id_and_created_at  (user_id,created_at)
#  index_pending_email_disposals_on_user_id_and_vendor_id   (user_id,vendor_id) UNIQUE
#

class PendingEmailDisposal < ApplicationRecord
  belongs_to :user
  belongs_to :email_thread, optional: true

  class << self
    def insert_attributes(user, email_ids)
      archive = user.option.archive
      email_ids.map { |email_id| { user_id: user.id, vendor_id: email_id, archive: archive } }
    end
  end
end
