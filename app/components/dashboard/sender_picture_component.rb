# frozen_string_literal: true

module Dashboard
  class SenderPictureComponent < ViewComponent::Base
    attr_reader :sender

    def initialize(sender)
      @sender = sender
    end

    def logo_url
      "https://img.logo.dev/#{sender.domain}?token=pk_fcoZ0tNaThuEj_GxBk6q9A&size=64"
    end

    def initials
      sender.name.split.map(&:first).join.upcase[0, 2]
    end
  end
end
