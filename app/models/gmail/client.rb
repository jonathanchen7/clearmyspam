# frozen_string_literal: true

require "google/apis/gmail_v1"

module Gmail
  class Client
    class_attribute :client, default: Rails.configuration.sandbox_mode ? SandboxGmailService.new : Google::Apis::GmailV1::GmailService.new

    THREAD_DETAILS_BATCH_SIZE = 20
    DISPOSE_BATCH_SIZE = Rails.configuration.sandbox_mode ? 100 : 15

    attr_reader :user

    def initialize(user)
      @user = user
    end

    # Returns the total number of threads and unread threads in the user's inbox.
    #
    # @return [Array<Integer>] An array containing [total_threads, unread_threads].
    def get_inbox_metrics!
      set_client_authorization

      response = client.get_user_label("me", "INBOX")

      [response.threads_total, response.threads_unread]
    end

    # Returns a list of Gmail thread IDs that match the provided query.
    #
    # @param max_results [Integer] The maximum number of threads to return.
    # @param page_token [String, nil] The page token to use for pagination.
    # @param query [String, nil] The query to filter the threads by.
    # @return [Array<String>, String>] A list of Gmail thread IDs and the next page token.
    def list_emails!(max_results: Rails.configuration.sender_dispose_all_max, page_token: nil, query: nil)
      set_client_authorization

      response = client.list_user_threads("me", max_results:, page_token:, label_ids:, q: query)
      return [[], nil] if response.threads.blank?

      [response.threads.map(&:id), response.next_page_token]
    end

    # Returns a list of Email objects with full thread details that match the provided query.
    #
    # @param max_results [Integer] The maximum number of threads to return (default: 20).
    # @param page_token [String, nil] The page token to use for pagination.
    # @param query [String, nil] The query to filter the threads by.
    # @return [Array<Email>, String>] A list of Email objects and the next page token.
    def get_emails!(max_results: Rails.configuration.sender_emails_per_page, page_token: nil, query: nil)
      set_client_authorization

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

    # Returns a list of unique Sender objects with their email counts from the user's inbox.
    #
    # @param max_results [Integer] The maximum number of threads to process (default: sync_fetch_count).
    # @param page_token [String, nil] The page token to use for pagination.
    # @return [Array<Sender>, String>] A list of Sender objects and the next page token.
    def get_unique_senders!(max_results: Rails.configuration.sync_fetch_count, page_token: nil)
      set_client_authorization

      response = client.list_user_threads("me", label_ids:, max_results:, page_token:)
      return [] unless response.threads.present?

      gmail_thread_ids = response.threads.map(&:id)
      google_threads = gmail_thread_ids.each_slice(THREAD_DETAILS_BATCH_SIZE).flat_map.with_index do |batch, index|
        sleep(1) unless index.zero?
        get_threads_batch_request(batch)
      end

      senders = google_threads.each_with_object({}) do |t, hash|
        sender = Sender.from_gmail_thread(t)
        next unless sender.present?

        hash[sender.id] = sender if !hash.key?(sender.id) || sender.newer_than?(hash[sender.id])
      end

      sender_thread_counts = get_thread_counts_for!(senders: senders.values)
      senders.each do |sender_id, sender|
        sender.email_count = sender_thread_counts[sender_id] || 0
      end

      user.protected_senders.where(sender_id: senders.keys).each do |protected_sender|
        senders[protected_sender.sender_id].protected = true
      end

      [senders.values, response.next_page_token]
    end

    # Returns a hash mapping sender IDs to their thread counts in the user's inbox.
    #
    # @param senders [Array<Sender>] The list of senders to get thread counts for.
    # @return [Hash<String, Integer>] A hash mapping sender IDs to their thread counts.
    def get_thread_counts_for!(senders: [])
      set_client_authorization

      return [] if senders.blank?

      sender_thread_counts = {}
      client.batch do |gmail|
        senders.each_slice(THREAD_DETAILS_BATCH_SIZE).each_with_index do |sender_batch, index|
          sleep(1) unless index.zero?

          sender_batch.each do |sender|
            gmail.list_user_threads("me", max_results: 500, q: sender.query_string, label_ids:) do |result, error|
              if error
                Rails.logger.error("Error fetching thread count for sender #{sender.id}: #{error}".on_red)
                sender_thread_counts[sender.id] = 0
              else
                count = result.threads&.size || 0
                sender_thread_counts[sender.id] = count
              end
            end
          end
        end
      end

      # If the count is 500, make more requests to get the exact count.
      senders_to_fetch_exact_count = senders.select { |sender| sender_thread_counts[sender.id] == 500 }
      senders_to_fetch_exact_count.each_with_index do |sender, index|
        sleep(0.5) unless index.zero?
        sender_thread_counts[sender.id] = get_thread_count!(query: sender.query_string, label_ids:)
      end

      sender_thread_counts
    end

    # Returns the number of Gmail threads that match the provided query.
    #
    # @param query [String, nil] An optional query string to filter the threads.
    # @param label_ids [Array<String>] An optional list of label IDs to filter the threads.
    # @return [Integer] The count of threads matching the query (max 2500).
    def get_thread_count!(query:, label_ids:)
      set_client_authorization

      response = client.list_user_threads("me", max_results: 500, q: query, label_ids:)
      return 0 unless response.threads&.any?

      total_count = response.threads.size
      while response.next_page_token && total_count < 2500
        response = client.list_user_threads("me", max_results: 500, q: query, page_token: response.next_page_token, label_ids:)
        break unless response.threads&.any?
        total_count += response.threads.size
      end

      total_count
    end

    # Returns the full details of a specific Gmail thread.
    #
    # @param thread_id [String] The ID of the thread to retrieve.
    # @return [Google::Apis::GmailV1::Thread] The full thread details.
    def get_thread_details!(thread_id:)
      set_client_authorization

      client.get_user_thread("me", thread_id, format: "full")
    end

    # Archives multiple Gmail threads by removing them from the INBOX label.
    #
    # @param thread_ids [Array<String>] The list of thread IDs to archive.
    # @return [void]
    # @raise [Google::Apis::Error] If any thread fails to archive.
    def archive_threads!(thread_ids)
      set_client_authorization

      client.batch do |gmail|
        thread_ids.each do |thread_id|
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

    # Moves multiple Gmail threads to the trash.
    #
    # @param thread_ids [Array<String>] The list of thread IDs to trash.
    # @return [void]
    # @raise [Google::Apis::Error] If any thread fails to trash.
    def trash_threads!(thread_ids)
      set_client_authorization

      client.batch do |gmail|
        thread_ids.each do |thread_id|
          gmail.trash_user_thread("me", thread_id) do |_res, error|
            if error
              Rails.logger.error("Error deleting thread #{thread_id}: #{error}".on_red)
              raise error
            end
          end
        end
      end
    end

    # Returns a list of custom labels in the user's Gmail account.
    #
    # @return [Array<Label>] The list of custom labels.
    def list_labels!
      set_client_authorization

      response = client.list_user_labels("me")
      response.labels.map { |label| Label.from_gmail_label(label) }.select(&:custom_label?)
    end

    # Moves multiple Gmail threads to a custom label.
    #
    # @param thread_ids [Array<String>] The list of thread IDs to move.
    # @param label_id [String] The ID of the label to move the threads to.
    def move_threads!(thread_ids:, label_id:)
      set_client_authorization

      client.batch do |gmail|
        thread_ids.each do |thread_id|
          gmail.modify_thread("me", thread_id, Google::Apis::GmailV1::ModifyThreadRequest.new(add_label_ids: [label_id], remove_label_ids: ["INBOX"])) do |_res, error|
            raise error if error
          end
        end
      end
    end

    private

    # Fetches a batch of Gmail threads with metadata headers.
    #
    # @param gmail_thread_ids [Array<String>] The list of thread IDs to fetch.
    # @return [Array<Google::Apis::GmailV1::Thread>] The fetched thread objects.
    # @raise [Google::Apis::Error] If any thread fails to fetch.
    def get_threads_batch_request(gmail_thread_ids)
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

    # Returns the label IDs to use for Gmail API requests based on user preferences.
    #
    # @return [Array<String>] The list of label IDs to include in requests.
    def label_ids
      label_ids = ["INBOX"]
      label_ids << "UNREAD" if user.option.unread_only?

      label_ids
    end

    # Sets up the Gmail client authorization using the user's Google access token.
    #
    # @return [void]
    def set_client_authorization
      user.refresh_google_auth!

      client.authorization = user.google_access_token
    end
  end
end
