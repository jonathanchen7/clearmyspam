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
      processed_count = email_tasks.delete_all

      ProcessEmailTasksJob.set(wait: 1.second).perform_later(user) if processed_count == TASK_PROCESSING_BATCH_SIZE
    end
  end

  private

  def acquire_advisory_lock
    lock_key = "process_email_tasks:#{user.id}"
    lock_id = Zlib.crc32(lock_key)
    acquired = ActiveRecord::Base.connection.select_value(
      ActiveRecord::Base.send(
        :sanitize_sql_array,
        ["SELECT pg_try_advisory_xact_lock(?)", lock_id]
      )
    )

    acquired
  end

  def email_tasks
    @email_tasks ||= user.email_tasks.order(created_at: :asc).limit(TASK_PROCESSING_BATCH_SIZE)
  end
end
