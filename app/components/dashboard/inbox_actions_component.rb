module Dashboard
  class InboxActionsComponent < ViewComponent::Base
    attr_reader :inbox

    def initialize(inbox)
      @inbox = inbox
    end
  end
end
