class DisposeEmailsJob < ApplicationJob
  queue_as :default

  attr_reader :user, :archive

  retry_on StandardError, attempts: 8, wait: ->(attempt) {
    # This calculates an exponential backoff delay in seconds between retry attempts
    # attempt 1: 2 * (2^1) = 4 seconds
    # attempt 2: 2 * (2^2) = 8 seconds
    # And so on...
    2 * (2 ** attempt)
  }

  def perform(user)
    Honeybadger.context(user)

    @user = user

    ApplicationRecord.transaction do
      return unless acquire_advisory_lock && pending_email_disposals.exists?

      user.refresh_google_auth!

      pending_email_disposals.group_by(&:archive).each do |archive, emails|
        next if emails.empty?

        vendor_ids = emails.map(&:vendor_id)
        if archive
          Gmail::Client.archive_threads!(user, *vendor_ids)
          user.metrics.archived_count += vendor_ids.count
        else
          Gmail::Client.trash_threads!(user, *vendor_ids)
          user.metrics.trashed_count += vendor_ids.count
        end
      end

      user.metrics.save!
      disposed_count = pending_email_disposals.delete_all

      DisposeEmailsJob.set(wait: 1.second).perform_later(user) if disposed_count == Gmail::Client::DISPOSE_BATCH_SIZE
    end
  end

  private

  def acquire_advisory_lock
    lock_key = "dispose_emails:#{user.id}:#{archive}"
    ApplicationRecord.sanitize_sql_for_conditions(["pg_try_advisory_xact_lock(?)", Zlib.crc32(lock_key)])
  end

  def pending_email_disposals
    @pending_email_disposals ||= user.pending_email_disposals
                                     .order(created_at: :asc)
                                     .limit(Gmail::Client::DISPOSE_BATCH_SIZE)
  end
end
