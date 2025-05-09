class Email
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

  class << self
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

    def bulk_dispose(user, vendor_ids:)
      archive = user.option.archive
      vendor_ids.each_slice(1000) do |vendor_ids_batch|
        disposal_attributes = vendor_ids_batch.map { |vendor_id| { user_id: user.id, vendor_id: vendor_id, archive: archive } }
        PendingEmailDisposal.insert_all(disposal_attributes, unique_by: %i[user_id vendor_id])
      end

      DisposeEmailsJob.perform_later(user)
    end

    private

    def extract_snippet(snippet)
      snippet
        .gsub(/[^\x20-\x7F]/, "") # Remove non-ASCII characters.
        .gsub(/\s+/, " ") # Replace multiple spaces with a single space.
        .gsub("&quot;", '"') # Replace HTML-escaped quotes with a ".
        .gsub(/&#(\d+);/) { |match| match.to_i.chr } # Replace HTML-escaped characters with actual chars.
    end
  end

  def sender
    @sender ||= Sender.new(raw_sender, as_of_date: date)
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
