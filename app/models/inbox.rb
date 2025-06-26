# frozen_string_literal: true

class Inbox
  module Actions
    PROTECT = 0
    UNPROTECT = 1
    ARCHIVE = 2
    TRASH = 3
  end

  class CachingError < StandardError; end

  attr_reader :user_id, :senders, :page_tokens, :metrics

  delegate :final_page_fetched?, :next_page_token, to: :page_tokens

  MAX_CAPACITY = 5000

  class << self
    def fetch_from_cache(user, &block)
      Rails.cache.fetch(cache_key(user.id), expires_in: 1.hour, &block)
    end

    def delete_from_cache!(user)
      Rails.cache.delete(cache_key(user.id))
    end

    def cache_key(user_id)
      "inbox/#{user_id}"
    end
  end

  def initialize(user_id)
    @user_id = user_id
    @senders = {}
    @page_tokens = PageTokens.new
    @metrics = InboxMetrics.new
  end

  # ------------------ MUTATIONS ------------------

  def populate(senders, page_token: nil)
    new_senders = senders.to_h { |sender| [sender.id, sender] }
    @senders.merge!(new_senders)
    @page_tokens.add(page_token)
  end

  def protect_senders(sender_ids)
    senders = senders_lookup(sender_ids)
    senders.each { |sender| sender.protected = true }
  end

  def unprotect_senders(sender_ids)
    senders = senders_lookup(sender_ids)
    senders.each { |sender| sender.protected = false }
  end

  def decrease_sender_email_count(sender_id, count)
    sender = senders[sender_id.to_s]
    sender.email_count = [sender.email_count - count, 0].max
  end

  def remove_senders(sender_ids)
    sender_ids.map { |sender_id| senders.delete(sender_id) }.compact
  end

  # ------------------ LOOKUPS ------------------

  def senders_lookup(sender_ids)
    senders.values_at(*sender_ids.map(&:to_s))
  end

  def sender_lookup(sender_id)
    senders[sender_id.to_s]
  end

  def sender_count
    senders.size
  end

  def email_count
    senders.values.sum(&:email_count)
  end

  # ------------------ CACHING ------------------

  def cache!
    Rails.cache.write(cache_key, self)
  end

  private

  def cache_key
    self.class.cache_key(user_id)
  end
end
