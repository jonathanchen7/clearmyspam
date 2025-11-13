# == Schema Information
#
# Table name: metrics
#
#  id                           :uuid             not null, primary key
#  archived_count               :integer          default(0), not null
#  failed_unsubscribe_count     :integer          default(0), not null
#  initial_total_threads        :integer          not null
#  initial_unread_threads       :integer          not null
#  moved_count                  :integer          default(0), not null
#  successful_unsubscribe_count :integer          default(0), not null
#  total_threads                :integer          not null
#  trashed_count                :integer          default(0), not null
#  unread_threads               :integer          not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  user_id                      :uuid             not null
#
# Indexes
#
#  index_metrics_on_user_id  (user_id) UNIQUE
#
class Metrics < ApplicationRecord
  belongs_to :user

  def disposed_count(range: nil)
    range.present? ? archived_count(range: range) + trashed_count(range: range) : archived_count + trashed_count
  end

  def archived_count(range: nil)
    range.present? ? sum_in_range(range, :archived_count) : read_attribute(:archived_count)
  end

  def trashed_count(range: nil)
    range.present? ? sum_in_range(range, :trashed_count) : read_attribute(:trashed_count)
  end

  def moved_count(range: nil)
    range.present? ? sum_in_range(range, :moved_count) : read_attribute(:moved_count)
  end

  def successful_unsubscribe_count(range: nil)
    range.present? ? sum_in_range(range, :successful_unsubscribe_count) : read_attribute(:successful_unsubscribe_count)
  end

  def failed_unsubscribe_count(range: nil)
    range.present? ? sum_in_range(range, :failed_unsubscribe_count) : read_attribute(:failed_unsubscribe_count)
  end

  private

  def sum_in_range(range, field)
    user.daily_metrics
        .where(date: range.begin..range.end)
        .sum(field)
  end
end
