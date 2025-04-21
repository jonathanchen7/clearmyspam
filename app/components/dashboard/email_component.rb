# frozen_string_literal: true

module Dashboard
  class EmailComponent < ViewComponent::Base
    def initialize(email:)
      @email = email
    end

    def email_subject
      email.subject || "No Subject"
    end

    def relative_date
      "#{time_ago_in_words(email.date)} ago"
    end

    def toggle_protection_button_path
      if email.protected?
        helpers.emails_unprotect_path
      else
        helpers.emails_protect_path
      end
    end

    def toggle_protection_button_icon
      if email.protected?
        helpers.icon("fa-solid", "lock-open", class: "text-warning")
      else
        helpers.icon("fa-solid", "lock", class: "text-success")
      end
    end

    def dispose_button_icon
      icon("fa-solid", Current.options.archive ? "box-archive" : "trash-can", class: "text-danger")
    end

    private

    attr_reader :email
  end
end
