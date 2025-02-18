# frozen_string_literal: true

require "google/apis/gmail_v1"

module Gmail
  class Client
    class_attribute :client, default: Google::Apis::GmailV1::GmailService.new

    THREAD_DETAILS_BATCH_SIZE = 20
    DISPOSE_BATCH_SIZE = 20

    class << self
      def get_inbox_metrics!(user)
        set_client_authorization(user)

        response = client.get_user_label("me", "INBOX")

        [response.threads_total, response.threads_unread]
      end

      # Returns the number of threads that match the provided query.
      #
      # @param user [User] The user whose threads are being counted.
      # @param query [String, nil] An optional query string to filter the threads.
      # @return [Integer] The count of threads matching the query (max 500).
      def get_thread_count!(user,
                            query:,
                            label_ids: ["INBOX"],
                            unread_only: false)
        set_client_authorization(user)

        label_ids << "UNREAD" if unread_only

        response = client.list_user_threads("me", max_results: 500, label_ids: label_ids, q: query)
        response.threads&.size || 0
      end

      def get_threads!(user,
                       max_results:,
                       page_token: nil,
                       label_ids: ["INBOX"],
                       unread_only: false,
                       query: nil)
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

          google_threads = gmail_thread_ids.each_slice(THREAD_DETAILS_BATCH_SIZE).flat_map.with_index do |batch, index|
            sleep(1) unless index.zero?
            get_threads_batch_request(batch)
          end

          email_threads = google_threads.map { |t| EmailThread.from_google_thread(t) }.compact
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
        user.refresh_google_auth! if user.google_auth_expired?

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
  end
end
