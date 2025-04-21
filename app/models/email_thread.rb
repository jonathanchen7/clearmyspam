# == Schema Information
#
# Table name: email_threads
#
#  id         :uuid             not null, primary key
#  archived   :boolean          default(FALSE), not null
#  protected  :boolean          default(FALSE), not null
#  trashed    :boolean          default(FALSE), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :uuid             not null
#  vendor_id  :string           not null
#
# Indexes
#
#  index_email_threads_on_user_id    (user_id)
#  index_email_threads_on_vendor_id  (vendor_id) UNIQUE
#
class EmailThread < ApplicationRecord
  belongs_to :user

  scope :archived, -> { where(archived: true) }
  scope :trashed, -> { where(trashed: true) }
  scope :disposed, -> { where(archived: true).or(where(trashed: true)) }
end
