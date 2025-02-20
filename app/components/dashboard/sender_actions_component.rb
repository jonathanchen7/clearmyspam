module Dashboard
  class SenderActionsComponent < ViewComponent::Base
    def initialize(sender, has_actionable_emails:, final_page_fetched:)
      @sender = sender
      @has_actionable_emails = has_actionable_emails
      @final_page_fetched = final_page_fetched
    end

    def protect_button_text
      @has_actionable_emails ? I18n.t("buttons.protect_all") : I18n.t("buttons.unprotect_all")
    end

    def protect_button_path
      @has_actionable_emails ? emails_protect_path : emails_unprotect_path
    end

    def dispose_button_text
      Current.options.archive ? I18n.t("buttons.archive_all") : I18n.t("buttons.delete_all")
    end
  end
end
