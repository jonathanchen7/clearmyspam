module Dashboard
  class SenderActionsComponent < ViewComponent::Base
    def initialize(sender)
      @sender = sender
    end

    def protect_button_text
      @sender.protected ? I18n.t("buttons.unprotect_sender") : I18n.t("buttons.protect_sender")
    end

    def protect_button_path
      @sender.protected ? senders_unprotect_path(sender_ids: [@sender.id]) : senders_protect_path(sender_ids: [@sender.id])
    end

    def dispose_button_text
      Current.options.archive ? I18n.t("buttons.archive_all") : I18n.t("buttons.delete_all")
    end
  end
end
