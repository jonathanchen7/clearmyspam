module Debug
  class GatherMetricsJob < ApplicationJob
    queue_as :default

    def perform(time_range: 24.hours.ago..Time.current, user_count: 5)
      stats = gather_basic_statistics(time_range)
      top_users = find_top_active_users(time_range, user_count)

      print_summary(time_range, stats, top_users)

      # Return the summary data for potential further use
      {
        period_start: time_range.begin,
        period_end: time_range.end,
        **stats,
        top_users: top_users
      }
    end

    private

    def gather_basic_statistics(time_range)
      {
        emails_synced: EmailThread.where(created_at: time_range).count,
        new_users: User.where(created_at: time_range).count,
        emails_disposed: EmailThread.disposed.where(updated_at: time_range).count,
        new_logins: User.where(last_login_at: time_range).count
      }
    end

    def find_top_active_users(time_range, user_count)
      active_user_ids = User.where(last_login_at: time_range).pluck(:id)

      User.where(id: active_user_ids)
          .joins(:email_threads)
          .where(email_threads: {
            trashed: true,
            updated_at: time_range
          })
          .or(
            User.where(id: active_user_ids)
                .joins(:email_threads)
                .where(email_threads: {
                  archived: true,
                  updated_at: time_range
                })
          )
          .group("users.id")
          .select("users.id, users.email, users.name, COUNT(email_threads.id) as disposed_count")
          .order("disposed_count DESC")
          .limit(user_count)
    end

    def print_summary(time_range, stats, top_users)
      puts "\n"
      puts "===== CLEAR MY SPAM: #{((time_range.end - time_range.begin) / 1.hour).round} HOUR SUMMARY ====="
      puts "Period:"
      puts "  Start: #{time_range.begin.in_time_zone('Pacific Time (US & Canada)').strftime('%Y-%m-%d %I:%M %p %Z')}"
      puts "  End:   #{time_range.end.in_time_zone('Pacific Time (US & Canada)').strftime('%Y-%m-%d %I:%M %p %Z')}"
      puts "\n"
      puts "----------------------------------------"
      puts "\n"
      puts "Total emails synced: #{stats[:emails_synced]}"
      puts "New users registered: #{stats[:new_users]}"
      puts "Emails disposed: #{stats[:emails_disposed]}"
      puts "New login sessions: #{stats[:new_logins]}"
      puts "\n"
      puts "----------------------------------------"
      puts "\n"
      puts "TOP 5 ACTIVE USERS (during this period):"
      puts "\n"

      if top_users.any?
        top_users.each_with_index do |user, index|
          puts "#{index + 1}. User ID: #{user.id}"
          puts "   Email: #{user.email}"
          puts "   Synced emails: #{user.email_threads.count}"
          puts "   Disposed emails: #{user.disposed_count}"
          puts "\n"

          unless index == top_users.length - 1
            puts "----------------"
            puts "\n"
          end
        end
      else
        puts "No users logged in during this period."
        puts "\n"
      end

      puts "========================================"
      puts "\n"
    end
  end
end
