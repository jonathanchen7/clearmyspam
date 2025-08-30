class Email
  class << self
    def protect_all!(user, vendor_ids)
      protected_email_attributes = vendor_ids.map { |vendor_id| { vendor_id: vendor_id } }
      user.protected_emails.upsert_all(protected_email_attributes, unique_by: %i[user_id vendor_id])
    end

    def unprotect_all!(user, vendor_ids)
      user.protected_emails.where(vendor_id: vendor_ids).delete_all
    end

    def dispose_all!(user, vendor_ids:)
      task_type = user.option.archive ? "archive" : "trash"
      vendor_ids.each_slice(1000) do |vendor_ids_batch|
        email_task_attributes = vendor_ids_batch.map { |vendor_id| { vendor_id: vendor_id, task_type: task_type } }
        user.email_tasks.upsert_all(email_task_attributes, unique_by: %i[user_id task_type vendor_id])
      end

      ProcessEmailTasksJob.perform_later(user)
    end

    # Converts a `Google::Apis::GmailV1::Thread` object into an `Email` object.
    #
    # @param thread [Google::Apis::GmailV1::Thread] The Gmail thread to convert.
    # @return [Email, nil] The converted Email object, or nil if one could not be extracted.
    def from_gmail_thread(gmail_thread)
      latest_message = gmail_thread.messages.first
      headers = latest_message.payload.headers

      sender = Sender.from_gmail_thread(gmail_thread)

      new(
        vendor_id: gmail_thread.id,
        sender: sender,
        date: sender.as_of_date,
        subject: fetch_gmail_header(headers, "Subject"),
        snippet: extract_snippet(latest_message.snippet),
        label_ids: latest_message.label_ids
      )
    rescue StandardError => e
      Honeybadger.notify(e)
      nil
    end

    def fetch_gmail_header(headers, name)
      headers.find { |header| header.name.downcase == name.downcase }&.value
    end

    def fetch_from_cache(sender_id)
      Rails.cache.read(cache_key(sender_id))
    end

    def write_to_cache(sender_id, emails)
      Rails.cache.write(cache_key(sender_id), emails, expires_in: 5.minutes)
    end

    private

    def extract_snippet(snippet)
      snippet
        .gsub(/[^\x20-\x7F]/, "") # Remove non-ASCII characters.
        .gsub(/\s+/, " ") # Replace multiple spaces with a single space.
        .gsub("&quot;", '"') # Replace HTML-escaped quotes with a ".
        .gsub(/&#(\d+);/) { |match| match.to_i.chr } # Replace HTML-escaped characters with actual chars.
    end

    def cache_key(sender_id)
      "sender_emails/#{sender_id}"
    end
  end

  attr_accessor :protected
  attr_reader :vendor_id, :sender, :date, :subject, :snippet, :label_ids

  def initialize(vendor_id:, sender:, date:, subject:, snippet:, label_ids:)
    @vendor_id = vendor_id
    @sender = sender
    @date = date
    @subject = subject
    @snippet = snippet
    @label_ids = label_ids
  end

  def fetch_gmail_details!(user)
    Gmail::Client.new(user).get_thread_details!(thread_id: vendor_id)
  end

  def unread?
    label_ids.include?("UNREAD")
  end

  def protected?
    return @protected if defined?(@protected)

    true
  end

  def actionable?
    !protected?
  end

  private

  def <=>(other)
    other.date <=> date
  end
end
