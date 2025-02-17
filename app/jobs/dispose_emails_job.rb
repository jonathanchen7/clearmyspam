class DisposeEmailsJob < ApplicationJob
  include EmailDisposalJob

  # If you change the signature of this method, make sure to also update the good_job concurrency controls.
  def perform(user, email_threads, archive:)
    return if email_threads.blank?

    user.refresh_google_auth! if user.google_auth_expired?

    if archive
      Gmail::Client.archive_threads!(user, *email_threads.map(&:vendor_id))
      user.email_threads.where(id: email_threads.map(&:id)).update_all(archived: true)
    else
      Gmail::Client.trash_threads!(user, *email_threads.map(&:vendor_id))
      user.email_threads.where(id: email_threads.map(&:id)).update_all(trashed: true)
    end
  end
end
