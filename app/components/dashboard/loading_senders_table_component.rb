module Dashboard
  class LoadingSendersTableComponent < ViewComponent::Base
    def initialize(inbox)
      @inbox = inbox
    end

    def hide?
      @inbox.present?
    end

    def row_count
      @inbox.present? ? [20, @inbox.sender_count].min : 20
    end
  end
end
