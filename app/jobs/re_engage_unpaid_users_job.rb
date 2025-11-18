class ReEngageUnpaidUsersJob < ApplicationJob
  queue_as :default

  attr_reader :date_range

  def perform(date_range: 1.week.ago..Time.current, sleep_interval: 1.second)
    @date_range = date_range

    result = { sent_re_engagement_emails: [], sent_re_engagement_reminder_emails: [] }
    active_unpaid_users.each do |user|
      re_engagement_email = user.sent_emails.find { |se| se.email_type == "re_engagement" }
      re_engagement_reminder_email = user.sent_emails.find { |se| se.email_type == "re_engagement_reminder" }

      next if re_engagement_email && re_engagement_reminder_email

      if !re_engagement_email
        SentEmail.send_re_engagement_email!(user)
        result[:sent_re_engagement_emails] << user.id
      elsif re_engagement_email.sent_at < 3.days.ago && !re_engagement_reminder_email
        SentEmail.send_re_engagement_reminder_email!(user)
        result[:sent_re_engagement_reminder_emails] << user.id
      end

      sleep sleep_interval
    end

    result
  end

  def active_unpaid_users
    @active_unpaid_users ||= User.unpaid
      .where(last_login_at: date_range, send_marketing_emails: true, created_at: ..2.days.ago)
      .where.not(
        id: User.joins(:sent_emails)
          .where(sent_emails: { email_type: ["re_engagement", "re_engagement_reminder"] })
          .group("users.id")
          .having("COUNT(DISTINCT sent_emails.email_type) = 2")
          .select("users.id")
      )
      .includes(:sent_emails)
  end
end
