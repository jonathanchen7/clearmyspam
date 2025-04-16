# == Schema Information
#
# Table name: pending_email_disposals
#
#  id              :uuid             not null, primary key
#  archive         :boolean          not null
#  created_at      :datetime         not null
#  email_thread_id :uuid             not null
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
  belongs_to :email_thread
end
