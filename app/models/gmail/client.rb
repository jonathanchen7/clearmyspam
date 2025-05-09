# frozen_string_literal: true

require "google/apis/gmail_v1"

module Gmail
  class Client
    class_attribute :client, default: Google::Apis::GmailV1::GmailService.new

    THREAD_DETAILS_BATCH_SIZE = 20
    DISPOSE_BATCH_SIZE = 15

    attr_reader :user

    class << self
      def get_inbox_metrics!(user)
        set_client_authorization(user)

        response = client.get_user_label("me", "INBOX")

        [response.threads_total, response.threads_unread]
      end

      def archive_threads!(user, *gmail_thread_ids)
        set_client_authorization(user)

        client.batch do |gmail|
          gmail_thread_ids.each do |thread_id|
            gmail.modify_thread(
              "me",
              thread_id,
              Google::Apis::GmailV1::ModifyThreadRequest.new(remove_label_ids: ["INBOX"])
            ) do |_res, error|
              if error
                Rails.logger.error("Error archiving thread #{thread_id}: #{error}".on_red)
                raise error
              end
            end
          end
        end
      end

      def trash_threads!(user, *gmail_thread_ids)
        set_client_authorization(user)

        client.batch do |gmail|
          gmail_thread_ids.each do |thread_id|
            gmail.trash_user_thread("me", thread_id) do |_res, error|
              if error
                Rails.logger.error("Error deleting thread #{thread_id}: #{error}".on_red)
                raise error
              end
            end
          end
        end
      end

      private

      def set_client_authorization(user)
        user.refresh_google_auth!

        client.authorization = user.google_access_token
      end
    end

    def initialize(user)
      @user = user
    end

    # Returns a list of Gmail thread IDs that match the provided query.
    #
    # @param max_results [Integer] The maximum number of threads to return.
    # @param page_token [String, nil] The page token to use for pagination.
    # @param label_ids [Array<String>] The label IDs to filter the threads by.
    # @param unread_only [Boolean] Whether to only return unread threads.
    # @param query [String, nil] The query to filter the threads by.
    # @return [Array<String>, String>] A list of Gmail thread IDs and the next page token.
    def list_emails!(max_results: 20, page_token: nil, label_ids: ["INBOX"], unread_only: false, query: nil)
      set_client_authorization

      label_ids << "UNREAD" if unread_only
      response = client.list_user_threads("me", max_results:, page_token:, label_ids:, q: query)
      return [[], nil] if response.threads.blank?

      [response.threads.map(&:id), response.next_page_token]
    end

    def get_emails!(max_results: 20, page_token: nil, label_ids: ["INBOX"], unread_only: false, query: nil)
      set_client_authorization

      label_ids << "UNREAD" if unread_only
      # threads.list uses 10 quota units. The max allowed value is 500.
      response = client.list_user_threads("me", max_results:, page_token:, label_ids:, q: query)
      return [[], nil] if response.threads.blank?

      gmail_threads = response.threads.map(&:id).each_slice(THREAD_DETAILS_BATCH_SIZE).flat_map.with_index do |batch, index|
        sleep(1) unless index.zero?
        get_threads_batch_request(batch)
      end

      emails = gmail_threads.map { |t| Email.from_gmail_thread(t) }.compact
      protected_emails = user.protected_emails.where(vendor_id: emails.map(&:vendor_id)).pluck(:vendor_id).to_set
      emails.each { |email| email.protected = protected_emails.include?(email.vendor_id) }

      [emails, response.next_page_token]
    end

    def get_unique_senders!(max_results: Rails.configuration.sync_fetch_count, page_token: nil)
      set_client_authorization

      response = client.list_user_threads("me", label_ids: ["INBOX"], max_results:, page_token:)

      return [] unless response.threads.any?

      gmail_thread_ids = response.threads.map(&:id)
      google_threads = gmail_thread_ids.each_slice(THREAD_DETAILS_BATCH_SIZE).flat_map.with_index do |batch, index|
        sleep(1) unless index.zero?
        get_threads_batch_request(batch)
      end

      senders = google_threads.each_with_object({}) do |t, hash|
        sender = Sender.from_gmail_thread(t)
        next unless sender.present?

        sender.email_count = get_thread_count!(query: "from:#{sender.email}")
        hash[sender.id] = sender if !hash.key?(sender.id) || sender.newer_than?(hash[sender.id])
      end

      # TODO: Mark protected senders.

      [senders.values, response.next_page_token]
    end

    # Returns the number of Gmail threads that match the provided query.
    #
    # @param query [String, nil] An optional query string to filter the threads.
    # @return [Integer] The count of threads matching the query (max 2500).
    def get_thread_count!(query:, label_ids: ["INBOX"], unread_only: false)
      set_client_authorization

      label_ids << "UNREAD" if unread_only
      response = client.list_user_threads("me", max_results: 500, label_ids: label_ids, q: query)
      return 0 unless response.threads&.any?

      total_count = response.threads.size
      while response.next_page_token && total_count < 2500
        response = client.list_user_threads("me", max_results: 500, label_ids: label_ids, q: query, page_token: response.next_page_token)
        break unless response.threads&.any?
        total_count += response.threads.size
      end

      total_count
    end

    def get_thread_details!(thread_id:)
      set_client_authorization

      client.get_user_thread("me", thread_id, format: "full")
    end

    private

    def set_client_authorization
      user.refresh_google_auth!

      client.authorization = user.google_access_token
    end

    def get_threads_batch_request(gmail_thread_ids)
      Rails.logger.info("Fetching batch of #{gmail_thread_ids.size} threads")
      gmail_threads = []
      client.batch do |gmail|
        gmail_thread_ids.each do |tid|
          # threads.get uses 10 quota units. Batch requests should be ~20 emails to avoid rate limits.
          gmail.get_user_thread("me", tid,
                                format: "metadata",
                                metadata_headers: %w[From Date Subject]) do |result, error|
            if error
              Rails.logger.error("Error fetching thread #{tid}: #{error}".on_red)
              raise error
            else
              gmail_threads << result
            end
          end
        end
      end

      gmail_threads
    end
  end
end
