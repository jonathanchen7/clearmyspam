require "stripe"

class ReEngageUnpaidUsersJob < ApplicationJob
  queue_as :default

  attr_reader :date_range

  def perform(date_range: 1.week.ago..Time.current, sleep_interval: 1.second)
    @date_range = date_range

    active_unpaid_users.each do |user|
      next if user.sent_email?("re_engagement") && user.sent_email?("re_engagement_reminder")

      if !user.sent_email?("re_engagement")
        SentEmail.send_re_engagement_email!(user)
      elsif user.sent_emails.find_by(email_type: "re_engagement").sent_at < 3.days.ago
        SentEmail.send_re_engagement_reminder_email!(user)
      end

      sleep sleep_interval
    end
  end

  private

  def active_unpaid_users
    @active_unpaid_users ||= User.unpaid.where(last_login_at: date_range, send_marketing_emails: true)
  end
end
