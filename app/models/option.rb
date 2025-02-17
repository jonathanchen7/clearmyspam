# == Schema Information
#
# Table name: options
#
#  id                    :uuid             not null, primary key
#  archive_email_threads :boolean          default(FALSE), not null
#  hide_personal_emails  :boolean          default(FALSE), not null
#  unread_only           :boolean          default(TRUE), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  user_id               :uuid
#
# Indexes
#
#  index_options_on_user_id  (user_id)
#
class Option < ApplicationRecord
  belongs_to :user
end
