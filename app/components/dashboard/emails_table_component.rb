module Dashboard
  class EmailsTableComponent < ViewComponent::Base
    def initialize(emails:)
      @emails = emails
    end
  end
end
