# == Schema Information
#
# Table name: email_tasks
#
#  id         :uuid             not null, primary key
#  attempts   :integer          default(0), not null
#  payload    :jsonb
#  task_type  :string           not null
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

  class << self
    def process_all!(user, tasks)
      process_archive_tasks!(user, tasks.select { |task| task.task_type == "archive" })
      process_trash_tasks!(user, tasks.select { |task| task.task_type == "trash" })
      process_move_tasks!(user, tasks.select { |task| task.task_type == "move" })
    end

    private

    def process_archive_tasks!(user, tasks)
      return if tasks.empty? || user.disable_dispose?

      vendor_ids = tasks.map(&:vendor_id)
      user.gmail_client.archive_threads!(vendor_ids)
      user.metrics.archived_count += vendor_ids.count
      user.metrics.save!
    end

    def process_trash_tasks!(user, tasks)
      return if tasks.empty? || user.disable_dispose?

      vendor_ids = tasks.map(&:vendor_id)
      user.gmail_client.trash_threads!(vendor_ids)
      user.metrics.trashed_count += vendor_ids.count
      user.metrics.save!
    end

    def process_move_tasks!(user, tasks)
      return if tasks.empty?

      tasks.group_by { |task| task.payload["label_id"] }.each do |label_id, tasks_for_label|
        vendor_ids = tasks_for_label.map(&:vendor_id)
        user.gmail_client.move_threads!(thread_ids: vendor_ids, label_id: label_id)
      end
    end
  end

  def process!
    case task_type
    when "archive"
      user.gmail_client.archive_threads!([vendor_id])
    when "trash"
      user.gmail_client.trash_threads!([vendor_id])
    when "move"
      user.gmail_client.move_threads!(thread_ids: [vendor_id], label_id: payload["label_id"])
    end
  end

  private

  def validate_payload_for_type
    case task_type
    when "archive", "trash"
      if payload.present?
        errors.add(:payload, "must be null for type '#{task_type}'")
      end
    when "move"
      unless payload.is_a?(Hash) && payload.key?("label_id")
        errors.add(:payload, "must include 'label_id' for type 'move'")
      end
    end
  end
end
