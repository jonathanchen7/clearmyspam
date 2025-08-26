# == Schema Information
#
# Table name: email_tasks
#
#  id         :uuid             not null, primary key
#  attempts   :integer          default(0), not null
#  payload    :jsonb
#  type       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :uuid             not null
#  vendor_id  :string           not null
#
# Indexes
#
#  index_email_tasks_on_user_id_and_created_at  (user_id,created_at)
#  index_email_tasks_on_user_id_and_vendor_id   (user_id,vendor_id) UNIQUE
#
class EmailTask < ApplicationRecord
  belongs_to :user

  validate :validate_payload_for_type

  private

  def validate_payload_for_type
    case type
    when "archive", "trash"
      if payload.present?
        errors.add(:payload, "must be null for type '#{type}'")
      end
    when "move"
      unless payload.is_a?(Hash) && payload.key?("label_id")
        errors.add(:payload, "must include 'label_id' for type 'move'")
      end
    end
  end
end
