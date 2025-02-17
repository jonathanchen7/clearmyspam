class DisposeEmailsFromSenderJob < ApplicationJob
  include EmailDisposalJob

  # If you change the signature of this method, make sure to also update the good_job concurrency controls.
  def perform(user, sender_email, unread_only:, archive:)
    return if sender_email.blank?

    user.refresh_google_auth! if user.google_auth_expired?

    email_thread_fetcher = EmailThreadFetcher.new(user)
    email_threads, _page_token =
      email_thread_fetcher.fetch_threads_from_email!(sender_email,
                                                     max_results: Rails.configuration.sender_dispose_all_max,
                                                     unread_only: unread_only)

    email_threads.each_slice(Gmail::Client::DISPOSE_BATCH_SIZE).with_index do |emails_slice, index|
      DisposeEmailsJob.set(wait: (index * 4).seconds).perform_later(user, emails_slice, archive: archive)
    end
  end
end
