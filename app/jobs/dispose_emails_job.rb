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

  def perform(user, archive:)
    Honeybadger.context(user)

    @user = user
    @archive = archive

    ApplicationRecord.transaction do
      return unless acquire_advisory_lock && pending_email_disposals.exists?

      user.refresh_google_auth!

      if archive
        Gmail::Client.archive_threads!(user, *pending_email_disposals.map(&:vendor_id))
      else
        Gmail::Client.trash_threads!(user, *pending_email_disposals.map(&:vendor_id))
      end

      archive ? email_threads.update_all(archived: true) : email_threads.update_all(trashed: true)
      disposed_count = pending_email_disposals.delete_all

      if disposed_count == Gmail::Client::DISPOSE_BATCH_SIZE
        DisposeEmailsJob.set(wait: 1.second).perform_later(user, archive: archive)
      end
    end
  end

  private

  def acquire_advisory_lock
    lock_key = "dispose_emails:#{user.id}:#{archive}"
    ApplicationRecord.sanitize_sql_for_conditions(["pg_try_advisory_xact_lock(?)", Zlib.crc32(lock_key)])
  end

  def pending_email_disposals
    @pending_email_disposals ||= user.pending_email_disposals
                                     .where(archive: archive)
                                     .order(created_at: :asc)
                                     .limit(Gmail::Client::DISPOSE_BATCH_SIZE)
  end

  def email_threads
    @email_threads ||= EmailThread.where(id: pending_email_disposals.map(&:email_thread_id))
  end
end
