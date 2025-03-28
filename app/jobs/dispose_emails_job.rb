class DisposeEmailsJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  queue_as :default

  good_job_control_concurrency_with(
    key: -> { "#{arguments.find { |arg| arg.is_a?(User) }.id}:dispose" },
    perform_limit: 3
  )

  retry_on RetryError,
           wait: ->(attempt) { [attempt < 10 ? rand(5..60) : (2**(attempt - 10)) * rand(60..180), 1200].min },
           attempts: 15

  # If you change the signature of this method, make sure to also update the good_job concurrency controls.
  def perform(user, email_threads, archive:)
    Honeybadger.context(user)

    return if email_threads.blank?

    user.refresh_google_auth! if user.google_auth_expired?

    if archive
      Gmail::Client.archive_threads!(user, *email_threads.map(&:vendor_id))
      user.email_threads.where(id: email_threads.map(&:id)).update_all(archived: true)
    else
      Gmail::Client.trash_threads!(user, *email_threads.map(&:vendor_id))
      user.email_threads.where(id: email_threads.map(&:id)).update_all(trashed: true)
    end
  rescue Google::Apis::RateLimitError, Google::Apis::ServerError, Google::Apis::ClientError
    raise RetryError
  end
end
