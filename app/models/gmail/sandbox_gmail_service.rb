require "faker" unless Rails.env.production?

include FactoryBot::Syntax::Methods unless Rails.env.production?

module Gmail
  class SandboxGmailService
    attr_accessor :authorization

    BASE_SEED = 42

    TOTAL_THREAD_COUNT_RANGE = 10_000..20_000
    UNREAD_THREAD_COUNT_RANGE = 1000..8000
    NUM_EMAILS_PER_SENDER_RANGE = 50..500
    NUM_SENDERS_PER_PAGE = 10

    def initialize
      raise "Faker is not available in production" if Rails.env.production?

      @next_page_token = nil
      @emails_cache = {}
    end

    # Mirrors Google::Apis::GmailV1::GmailService#get_user_label
    GetUserLabelResponse = Struct.new(:threads_total, :threads_unread, keyword_init: true)
    def get_user_label(user_id, label_id)
      Faker::Config.random = Random.new(BASE_SEED + label_id.hash)
      total_threads = Faker::Number.between(from: TOTAL_THREAD_COUNT_RANGE.min, to: TOTAL_THREAD_COUNT_RANGE.max)
      unread_threads = Faker::Number.between(from: UNREAD_THREAD_COUNT_RANGE.min, to: UNREAD_THREAD_COUNT_RANGE.max)
      GetUserLabelResponse.new(threads_total: total_threads, threads_unread: unread_threads)
    end

    # Mirrors Google::Apis::GmailV1::GmailService#list_user_threads
    ListThreadsResponse = Struct.new(:threads, :next_page_token, keyword_init: true)
    ListThread = Struct.new(:id, keyword_init: true)
    def list_user_threads(user_id, max_results:, page_token: nil, label_ids: nil, q: nil, &block)
      Faker::Config.random = Random.new(BASE_SEED + q.hash + page_token.hash + label_ids.hash)
      num_threads = if specific_sender_query?(q) && max_results != Rails.configuration.sender_emails_per_page
                      Faker::Number.between(from: NUM_EMAILS_PER_SENDER_RANGE.min, to: NUM_EMAILS_PER_SENDER_RANGE.max)
                    else
                      max_results
                    end

      sender_email = q[5..] if specific_sender_query?(q)
      threads = num_threads.times.map do
        thread_id = Faker::Alphanumeric.alphanumeric(number: 16)
        thread_id = "#{Digest::MD5.hexdigest(sender_email)}-#{thread_id}" if sender_email.present?
        ListThread.new(id: thread_id)
      end

      result = ListThreadsResponse.new(
        threads: threads,
        next_page_token: Faker::Alphanumeric.alphanumeric(number: 16)
      )

      block_given? ? yield(result, nil) : result
    end

    # Mirrors Google::Apis::GmailV1::GmailService#get_user_thread
    ThreadResponse = Struct.new(:id, :messages, keyword_init: true)
    Message = Struct.new(:id, :payload, :snippet, :label_ids, keyword_init: true)
    MessagePayload = Struct.new(:headers, :parts, :mime_type, :body, keyword_init: true)
    PayloadHeader = Struct.new(:name, :value, keyword_init: true)
    MessagePartBody = Struct.new(:data, :size, keyword_init: true)
    def get_user_thread(user_id, thread_id, format:, metadata_headers: nil, &block)
      Faker::Config.random = Random.new(BASE_SEED + thread_id.hash)

      if specific_sender_thread_id?(thread_id)
        hashed_sender_email = thread_id.split("-").first
        sender = build(:sender, :business, email: Sender::HASHED_DUMMY_BUSINESS_SENDERS[hashed_sender_email])
      else
        sender = build(:sender, :business)
      end

      email = build(:email, sender:)
      headers = [
        PayloadHeader.new(name: "List-Unsubscribe", value: "https://example.com/unsubscribe"),
        PayloadHeader.new(name: "From", value: email.sender.raw_sender),
        PayloadHeader.new(name: "Date", value: email.date.to_s),
        PayloadHeader.new(name: "Subject", value: email.subject),
        PayloadHeader.new(name: "To", value: "user@example.com"),
        PayloadHeader.new(name: "Message-ID", value: "<#{Faker::Alphanumeric.alphanumeric(number: 16)}@example.com>"),
        PayloadHeader.new(name: "MIME-Version", value: "1.0"),
        PayloadHeader.new(name: "Content-Type", value: "text/html; charset=UTF-8"),
        PayloadHeader.new(name: "Content-Transfer-Encoding", value: "quoted-printable")
      ]

      html_content = load_email_template(thread_id)

      payload = MessagePayload.new(
        headers: headers,
        mime_type: "text/html",
        body: MessagePartBody.new(
          data: html_content,
          size: html_content.bytesize
        ),
        parts: nil
      )

      messages = [Message.new(id: thread_id, payload:, snippet: email.snippet, label_ids: email.label_ids)]
      result = ThreadResponse.new(id: thread_id, messages:)

      block_given? ? yield(result, nil) : result
    end

    # Mirrors Google::Apis::GmailV1::GmailService#modify_thread
    def modify_thread(user_id, thread_id, modify_request, &block)
      yield nil, nil
    end

    # Mirrors Google::Apis::GmailV1::GmailService#trash_user_thread
    def trash_user_thread(user_id, thread_id, &block)
      yield nil, nil
    end

    ListLabelsResponse = Struct.new(:labels, keyword_init: true)
    Label = Struct.new(:id, :name, keyword_init: true)
    def list_user_labels(user_id, &block)
      Faker::Config.random = Random.new(BASE_SEED)
      num_labels = Faker::Number.between(from: 5, to: 10)
      labels = num_labels.times.map do
        Label.new(id: "label_#{Faker::Alphanumeric.alphanumeric(number: 8)}", name: Faker::Lorem.word.capitalize)
      end
      result = ListLabelsResponse.new(labels:)

      block_given? ? yield(result, nil) : result
    end

    # Mirrors Google::Apis::GmailV1::GmailService#batch
    def batch
      raise ArgumentError, "Block required for batch calls" unless block_given?

      yield self
    end

    private

    def specific_sender_query?(q)
      q&.start_with?("from:") && Sender::HASHED_DUMMY_BUSINESS_SENDERS.key?(Digest::MD5.hexdigest(q[5..]))
    end

    def specific_sender_thread_id?(thread_id)
      thread_id.include?("-") && Sender::HASHED_DUMMY_BUSINESS_SENDERS.key?(thread_id.split("-").first)
    end

    def load_email_template(thread_id)
      templates = %w[promotional newsletter transactional simple welcome password_reset social_notification shipping survey]
      template_index = Faker::Number.between(from: 0, to: templates.size - 1)
      template_name = templates[template_index]
      template_path = Rails.root.join("app", "models", "gmail", "templates", "#{template_name}.html")

      if File.exist?(template_path)
        File.read(template_path)
      else
        "<html><body><p>Email content</p></body></html>"
      end
    end
  end
end
