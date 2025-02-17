# frozen_string_literal: true

require "colorize"

class EmailThreadFetcher
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def fetch_threads_from_email!(email, unread_only:, max_results: nil, sender_page_token: nil)
    max_results ||= Rails.configuration.sync_fetch_count

    query = "from:#{email}"
    fetch_threads!(
      max_results: max_results,
      unread_only: unread_only,
      query: query,
      page_token: sender_page_token
    )
  end

  def fetch_threads!(unread_only:, max_results: nil, query: nil, page_token: nil)
    max_results ||= Rails.configuration.sync_fetch_count
    Rails.logger.info("Fetching #{max_results} threads for user: #{user.id}".on_blue)

    threads, next_page_token = Gmail::Client.get_threads!(
      user,
      max_results: max_results,
      unread_only: unread_only,
      query: query,
      page_token: page_token,
    )
    persisted_thread_attributes = upsert_threads(threads)

    raise "Thread details count mismatch" if threads.count != persisted_thread_attributes.count

    email_threads = assign_thread_attributes(threads, persisted_thread_attributes)

    [email_threads, next_page_token]
  end

  private

  def upsert_threads(threads)
    EmailThread.upsert_all(
      threads.map(&:upsert_attributes),
      unique_by: :vendor_id,
      update_only: %w[trashed archived],
      returning: %w[id vendor_id protected created_at updated_at]
    )
  end

  def assign_thread_attributes(threads, thread_attributes)
    sorted_thread_attributes = thread_attributes.sort_by { |detail| detail["vendor_id"] }
    sorted_threads = threads.sort_by(&:vendor_id)

    sorted_threads.zip(sorted_thread_attributes).each do |thread, detail|
      raise "Thread ID mismatch" if thread.vendor_id != detail["vendor_id"]
      thread.assign_attributes(**detail)
    end

    sorted_threads
  end
end
