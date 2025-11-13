# == Schema Information
#
# Table name: daily_metrics
#
#  id                           :uuid             not null, primary key
#  archived_count               :integer          default(0), not null
#  date                         :date             not null
#  failed_unsubscribe_count     :integer          default(0), not null
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
#  index_daily_metrics_on_user_id_and_date  (user_id,date) UNIQUE
#
class DailyMetrics < ApplicationRecord
  belongs_to :user

  def increment_archived_count!(by: 1)
    self.archived_count += by
    user.metrics.archived_count += by
    user.metrics.save!
    save!
  end

  def increment_trashed_count!(by: 1)
    self.trashed_count += by
    user.metrics.trashed_count += by
    user.metrics.save!
    save!
  end

  def increment_moved_count!(by: 1)
    self.moved_count += by
    user.metrics.moved_count += by
    user.metrics.save!
    save!
  end

  def increment_successful_unsubscribe_count!(by: 1)
    self.successful_unsubscribe_count += by
    user.metrics.successful_unsubscribe_count += by
    user.metrics.save!
    save!
  end

  def increment_failed_unsubscribe_count!(by: 1)
    self.failed_unsubscribe_count += by
    user.metrics.failed_unsubscribe_count += by
    user.metrics.save!
    save!
  end
end
