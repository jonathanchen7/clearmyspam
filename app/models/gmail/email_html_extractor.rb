# frozen_string_literal: true

module Gmail
  class EmailHtmlExtractor
    class << self
      # Extracts HTML content from a Gmail thread.
      #
      # @param thread [Google::Apis::GmailV1::Thread] The Gmail thread object.
      # @return [String, nil] The HTML content of the thread, or nil if not found.
      def extract_html(thread)
        return nil unless thread&.messages&.any?

        thread.messages.each do |message|
          html = extract_html_from_message(message.payload)
          return html if html.present?
        end

        nil
      end

      private

      # Recursively extracts HTML from a message part.
      #
      # @param message_part [Google::Apis::GmailV1::MessagePart] The message part to extract from.
      # @return [String, nil] The HTML content, or nil if not found.
      def extract_html_from_message(message_part)
        return nil unless message_part

        if message_part.mime_type == "text/html" && message_part.body&.data && message_part.body.size > 0
          return message_part.body.data
        end

        message_part.parts&.each do |part|
          html = extract_html_from_message(part)
          return html if html.present?
        end

        nil
      end
    end
  end
end
