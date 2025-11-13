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

  def disposed_count
    archived_count + trashed_count
  end
end
