# frozen_string_literal: true

require "cgi"

module Dashboard
  class EmailPreviewComponent < ViewComponent::Base
    def initialize(email:, email_html:)
      @email = email
      @email_html = email_html
    end

    private

    attr_reader :email, :email_html

    def protected?
      email&.protected?
    end

    def email_subject
      email&.subject || "No subject"
    end

    def formatted_date
      email&.date&.strftime("%B %d, %Y at %I:%M %p") || "Date unavailable"
    end

    def has_content?
      email_html.present?
    end

    # Generates wrapped HTML content for display in an iframe.
    # This isolates the email's HTML/CSS from the parent page.
    #
    # @return [String] Base64-encoded data URI for use in iframe src attribute.
    def wrapped_email_html
      return nil unless email_html.present?

      html_content = <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            a {
              pointer-events: none;
              cursor: default;
              text-decoration: inherit;
            }
            button, input[type="submit"], input[type="button"] {
              pointer-events: none;
              cursor: default;
            }
          </style>

        </head>
        <body>
          #{email_html}
        </body>
        </html>
      HTML

      base64_html = Base64.strict_encode64(html_content)
      "data:text/html;charset=utf-8;base64,#{base64_html}"
    end
  end
end
