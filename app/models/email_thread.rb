# == Schema Information
#
# Table name: email_threads
#
#  id         :uuid             not null, primary key
#  archived   :boolean          default(FALSE), not null
#  protected  :boolean          default(FALSE), not null
#  trashed    :boolean          default(FALSE), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :uuid             not null
#  vendor_id  :string           not null
#
# Indexes
#
#  index_email_threads_on_user_id    (user_id)
#  index_email_threads_on_vendor_id  (vendor_id) UNIQUE
#
class EmailThread < ApplicationRecord
  belongs_to :user

  attribute :sender
  attribute :date, :datetime
  attribute :subject, :string
  attribute :snippet, :string
  attribute :label_ids, :string, array: true, default: []

  scope :archived, -> { where(archived: true) }
  scope :trashed, -> { where(trashed: true) }
  scope :disposed, -> { where(archived: true).or(where(trashed: true)) }

  class << self
    # Converts a `Google::Apis::GmailV1::Thread` object into an `EmailThread` object.
    #
    # @param thread [Google::Apis::GmailV1::Thread] The Google thread to convert.
    # @return [EmailThread, nil] The converted EmailThread object, or nil if one could not be extracted.
    def from_google_thread(thread)
      latest_message = thread.messages.first
      headers = latest_message.payload.headers
      raw_sender = fetch_gmail_header(headers, "From")
      raw_date = fetch_gmail_header(headers, "Date")

      if raw_sender.present? && raw_date.present?
        date = DateTime.parse(raw_date)
        # Since we store the sender on the EmailThread instead of the sender_id, it may be out of date.
        # Reference inbox.senders for the most up-to-date sender information.
        new(
          sender: Sender.new(raw_sender, as_of_date: date),
          vendor_id: thread.id,
          date: date,
          subject: fetch_gmail_header(headers, "Subject"),
          snippet: parse_snippet(latest_message.snippet),
          label_ids: latest_message.label_ids,
          trashed: false,
          archived: false
        )
      end
    rescue StandardError => e
      Rails.logger.error("Error creating EmailThread from Google thread: #{thread.id}")
      Honeybadger.notify(e)
      nil
    end

    def bulk_dispose(user, email_threads, archive:)
      email_threads.each_slice(1000) do |thread_batch|
        disposal_attributes = thread_batch.map { |thread| thread.pending_disposal_attributes(archive: archive) }
        PendingEmailDisposal.insert_all(disposal_attributes, unique_by: %i[user_id vendor_id])
      end

      DisposeEmailsJob.perform_later(user)
    end

    def fetch_gmail_header(headers, name)
      headers.find { |header| header.name == name }&.value
    end

    private

    def parse_snippet(snippet)
      snippet
        .gsub(/[^\x20-\x7F]/, "") # Remove non-ASCII characters.
        .gsub(/\s+/, " ") # Replace multiple spaces with a single space.
        .gsub("&quot;", '"') # Replace HTML-escaped quotes with a ".
        .gsub(/&#(\d+);/) { |match| match.to_i.chr } # Replace HTML-escaped characters with actual chars.
    end
  end

  def pending_disposal_attributes(archive:)
    {
      user_id: user_id,
      email_thread_id: id,
      vendor_id: vendor_id,
      archive: archive
    }
  end

  def fetch_gmail_details!(user)
    Gmail::Client.get_thread_details!(user, thread_id: vendor_id)
  end

  def unread?
    label_ids.include?("UNREAD")
  end

  def actionable?
    !protected?
  end

  def upsert_attributes
    {
      user_id: user_id,
      vendor_id: vendor_id,
      trashed: trashed,
      archived: archived
    }
  end
end
