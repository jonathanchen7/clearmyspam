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

      def get_thread_count!(user, query:, label_ids: ["INBOX"], unread_only: false)
        new(user).get_thread_count!(query:, label_ids:, unread_only:)
      end

      def get_threads!(user,
                       max_results:,
                       page_token: nil,
                       label_ids: ["INBOX"],
                       unread_only: false,
                       query: nil,
                       no_details: false)
        set_client_authorization(user)

        label_ids << "UNREAD" if unread_only
        # threads.list uses 10 quota units. The max allowed value is 500.
        response = client.list_user_threads("me",
                                            max_results: max_results,
                                            page_token: page_token,
                                            label_ids: label_ids,
                                            q: query)
        if (gmail_threads = response.threads.presence)
          gmail_thread_ids = gmail_threads.map(&:id)

          email_threads = if no_details
                            gmail_thread_ids.map { |id| EmailThread.new(vendor_id: id) }
                          else
                            google_threads = gmail_thread_ids.each_slice(THREAD_DETAILS_BATCH_SIZE).flat_map.with_index do |batch, index|
                              sleep(1) unless index.zero?
                              get_threads_batch_request(batch)
                            end
                            google_threads.map { |t| EmailThread.from_google_thread(t) }.compact
                          end

          email_threads.each { |thread| thread.user_id = user.id }
        else
          email_threads = []
        end

        [email_threads, response.next_page_token]
      end

      def get_thread_details!(user, thread_id:)
        set_client_authorization(user)

        client.get_user_thread("me", thread_id, format: "full")
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

      def get_threads_batch_request(gmail_thread_ids)
        Rails.logger.info("Fetching batch of #{gmail_thread_ids.size} threads")
        google_threads = []
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
                google_threads << result
              end
            end
          end
        end

        google_threads
      end
    end

    def initialize(user)
      @user = user
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
        sender = Sender.extract_from_gmail_thread(t)

        hash[sender.id] = sender if sender.present? && (!hash.key?(sender.id) || sender.newer_than?(hash[sender.id]))
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
