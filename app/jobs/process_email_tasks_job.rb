class ProcessEmailTasksJob < ApplicationJob
  queue_as :default

  attr_reader :user

  TASK_PROCESSING_BATCH_SIZE = 20

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
      return unless acquire_advisory_lock && email_tasks.exists?

      EmailTask.process_all!(user, email_tasks)
      email_tasks.delete_all
    end
  end

  private

  def acquire_advisory_lock
    lock_key = "process_email_tasks:#{user.id}"
    ApplicationRecord.sanitize_sql_for_conditions(["pg_try_advisory_xact_lock(?)", Zlib.crc32(lock_key)])
  end

  def email_tasks
    @email_tasks ||= user.email_tasks.order(created_at: :asc).limit(TASK_PROCESSING_BATCH_SIZE)
  end
end
