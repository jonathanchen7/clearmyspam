# frozen_string_literal: true

class UnsubscribeLinkFinder
  UNSUBSCRIBE_REGEXES = [
    /unsubscrib/i, # Includes "unsubscribe" and "unsubscribing"
    /opt( ?|-|ing |ing-)out/i, # Includes "opt out", "opt-out", and "opting-out"
    /(?:manage|update|adjust)[\s\S]{0,20}(?:subscription|notification|preference)/i # Includes "manage (your) notifications" and "manage preferences"
  ].freeze

  LINK_REGEX = /https?:\/\/[\w.-]+\.[a-z]{2,6}\b[\w\/?&=%.~#-]*/i

  class << self
    def find_link!(user, email_thread)
      thread_details = email_thread.fetch_gmail_details!(user)

      thread_details.messages.each do |message|
        link = check_headers_for_unsubscribe_link(message.payload.headers)
        return link if link.present?
      end

      encoded_parts_data = []
      thread_details.messages.each do |message|
        encoded_parts_data = get_data_from_parts(message.payload)
      end

      if encoded_parts_data.present?
        encoded_parts_data.each do |data|
          link = data_is_html?(data) ? find_link_in_html(data) : find_link_in_text(data)
          return link if link.present?
        end
      end

      nil
    end

    def check_headers_for_unsubscribe_link(headers)
      raw_link = EmailThread.fetch_gmail_header(headers, "List-Unsubscribe")
      if raw_link.present?
        $1 if raw_link =~ /(#{LINK_REGEX.source})/
      end
    end

    def find_link_in_html(html)
      anchor_tags = Nokogiri::HTML(html).css("a")
      anchor_tags.each do |anchor_tag|
        return anchor_tag["href"] if matches_unsubscribe_regex(anchor_tag["href"])
        return anchor_tag["href"] if search_for_unsubscribe(anchor_tag)
      end

      nil
    end

    def find_link_in_text(data)
      UNSUBSCRIBE_REGEXES.each do |regex|
        full_regex = /#{regex.source}[\s\S]{0,75}(#{LINK_REGEX.source})/i
        return $1 if data =~ full_regex
      end

      nil
    end

    private

    def get_data_from_parts(message_part)
      parts_with_data = []
      parts_with_data << message_part.body.data if message_part.body.size > 100

      if message_part.parts&.any?
        message_part.parts.each do |child_part|
          parts_with_data.concat(get_data_from_parts(child_part))
        end
      end

      parts_with_data
    end

    # I haven't yet found an example of an email that needs to be decoded yet, but this might come up.
    def decode_data(encoded_data)
      encoded_data
    end

    def data_is_html?(data)
      html_tags = ["<!DOCTYPE html", "<html"]
      html_tags.any? { |tag| data.include?(tag) }
    end

    def search_for_unsubscribe(node)
      return true if node.text.present? && matches_unsubscribe_regex(node.text)

      node.children.any? { |child_node| search_for_unsubscribe(child_node) }
    end

    def matches_unsubscribe_regex(text)
      UNSUBSCRIBE_REGEXES.any? { |regex| regex.match?(text) }
    end
  end
end
