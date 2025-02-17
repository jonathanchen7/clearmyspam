# frozen_string_literal: true

class Inbox
  module Actions
    PROTECT = 0
    UNPROTECT = 1
    ARCHIVE = 2
    TRASH = 3
  end

  attr_reader :user_id, :emails, :senders, :page_tokens, :metrics

  delegate :size, to: :emails
  delegate :final_page_fetched?, :next_page_token, to: :page_tokens

  INBOX_MAX_SIZE = 5000

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
    @emails = {}
    @senders = {}
    @page_tokens = PageTokens.new
    @metrics = InboxMetrics.new
  end

  # Populates the inbox with the given email threads.
  #
  # @param [Array<EmailThread>] email_threads
  # @param [String, nil] page_token The token for the next page of results, if any.
  # @param [Boolean] single_sender True if all email threads are from a single sender.
  # @return [Integer] The number of new email threads added to the inbox.
  # @raise [ArgumentError] If neither next_page_token and sender_page_token are provided.
  def populate(email_threads, page_token: nil, single_sender: false)
    return if email_threads.blank?

    new_email_count = email_threads.count do |email_thread|
      next if emails.key?(email_thread.id)

      email_sender = email_thread.sender
      senders[email_sender.id] = email_sender if !senders.key?(email_sender.id) || email_sender.newer_than?(senders[email_sender.id])

      emails[email_thread.id] = email_thread
    end

    if single_sender
      page_tokens.add(page_token, sender_id: email_threads.first.sender.id)
    else
      page_tokens.add(page_token)
    end

    new_email_count
  end

  # @param [Array<EmailThread>] email_threads
  def protect!(email_threads)
    return unless email_threads.present?

    EmailThread.transaction do
      EmailThread.where(id: email_threads.map(&:id)).update_all(protected: true)
      email_threads.each { |email_thread| emails[email_thread.id].protected = true }
    end
  end

  # @param [Array<EmailThread>] email_threads
  def unprotect!(email_threads)
    return unless email_threads.present?

    EmailThread.transaction do
      EmailThread.where(id: email_threads.map(&:id)).update_all(protected: false)
      email_threads.each { |email_thread| emails[email_thread.id].protected = false }
    end
  end

  # @param [Array<EmailThread>] email_threads
  def archive!(email_threads)
    return unless email_threads.present?

    EmailThread.transaction do
      EmailThread.where(id: email_threads.map(&:id)).update_all(archived: true)
      email_threads.select { |email_thread| emails.delete(email_thread.id) }
    end
  end

  # @param [Array<EmailThread>] email_threads
  def trash!(email_threads)
    return unless email_threads.present?

    EmailThread.transaction do
      EmailThread.where(id: email_threads.map(&:id)).update_all(trashed: true)
      email_threads.select { |email_thread| emails.delete(email_thread.id) }
    end
  end

  def emails_by_sender(hide_personal_emails: false)
    # There's an edge case where EmailThreads from the same email address (with different sender objects) are grouped
    # together. In this case, the sender for whichever EmailThread is processed first will be the sender for the group.
    # To address this, we sort the emails by date (newest first) before grouping them.
    email_threads = all_emails.sort_by(&:date)
                              .reverse
                              .group_by(&:sender)
                              .sort_by { |_, sender_emails| -sender_emails.size }
                              .to_h
    email_threads = email_threads.reject { |sender, _| sender.personal? } if hide_personal_emails

    email_threads
  end

  def sender_emails(*sender_ids, sorted: false)
    email_threads = all_emails.select { |email_thread| sender_ids.include?(email_thread.sender.id) }
    email_threads = email_threads.sort_by(&:date).reverse if sorted

    email_threads
  end

  def senders_lookup(sender_ids)
    senders.values_at(*sender_ids.map(&:to_i))
  end

  def sender_lookup(sender_id)
    senders[sender_id.to_i]
  end

  def cache!
    Rails.cache.write(cache_key, self)
  end

  def sender_count
    senders.size
  end

  private

  def all_emails
    emails.values
  end

  def cache_key
    self.class.cache_key(user_id)
  end
end
