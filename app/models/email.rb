class Email
  attr_reader :vendor_id, :raw_sender, :date, :subject, :snippet, :label_ids

  def initialize(vendor_id:, raw_sender:, date:, subject:, snippet:, label_ids:)
    @vendor_id = vendor_id
    @raw_sender = raw_sender
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

      new(
        vendor_id: gmail_thread.id,
        raw_sender: fetch_gmail_header(headers, "From"),
        date: DateTime.parse(fetch_gmail_header(headers, "Date")),
        subject: fetch_gmail_header(headers, "Subject"),
        snippet: extract_snippet(latest_message.snippet),
        label_ids: latest_message.label_ids
      )
    rescue StandardError => e
      raise e
      Honeybadger.notify(e)
      nil
    end

    def fetch_gmail_header(headers, name)
      headers.find { |header| header.name == name }&.value
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
    Gmail::Client.get_thread_details!(user, thread_id: vendor_id)
  end

  def unread?
    label_ids.include?("UNREAD")
  end

  def protected?
    @protected ||= ProtectedEmail.exists?(user: user, vendor_id: vendor_id)
  end
end
