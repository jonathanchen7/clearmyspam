module Dashboard
  class EmailThreadComponent < ViewComponent::Base
    def initialize(email_thread:)
      @email_thread = email_thread
    end

    def email_subject
      email_thread.subject || "No Subject"
    end

    def relative_date
      "#{time_ago_in_words(email_thread.date)} ago"
    end

    def toggle_protection_button_path
      if email_thread.protected?
        helpers.emails_unprotect_path
      else
        helpers.emails_protect_path
      end
    end

    def toggle_protection_button_icon
      if email_thread.protected?
        helpers.icon("fa-solid", "lock-open", class: "text-warning")
      else
        helpers.icon("fa-solid", "lock", class: "text-success")
      end
    end

    def dispose_button_icon
      icon("fa-solid", Current.options.archive ? "box-archive" : "trash-can", class: "text-danger")
    end

    private

    attr_reader :email_thread
  end
end
