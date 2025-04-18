class PageTokens
  END_OF_RESULTS = "end_of_results".freeze

  attr_reader :inbox_page_tokens, :sender_page_tokens

  def initialize
    @inbox_page_tokens = []
    @sender_page_tokens = {}
  end

  def add(page_token, sender_id: nil)
    page_token_to_add = page_token || END_OF_RESULTS

    if sender_id.present?
      sender_page_tokens[sender_id] ||= []
      sender_page_tokens[sender_id] << page_token_to_add unless duplicate_token?(page_token_to_add, sender_id: sender_id)
    else
      inbox_page_tokens << page_token_to_add unless duplicate_token?(page_token_to_add)
    end
  end

  # Checks if the final page has been fetched for a given sender or the inbox.
  #
  # @param sender_id [Integer, nil] the ID of the sender, or nil for the inbox
  # @return [Boolean] true if the final page has been fetched, false otherwise
  def final_page_fetched?(sender_id: nil)
    (sender_id.present? ? sender_page_tokens[sender_id] : inbox_page_tokens)&.last == END_OF_RESULTS
  end

  def next(sender_id: nil)
    next_page_token(sender_id: sender_id)
  end

  def next_page_token(sender_id: nil)
    raise ArgumentError, "Final page has already been fetched" if final_page_fetched?(sender_id: sender_id)

    if sender_id.present?
      sender_page_tokens[sender_id]&.last
    else
      inbox_page_tokens.last
    end
  end

  def for(page: 1, sender_id: nil)
    if sender_id.present?
      sender_page_tokens[sender_id]&.[](page - 1)
    else
      inbox_page_tokens[page - 1]
    end
  end

  private

  def duplicate_token?(page_token, sender_id: nil)
    if sender_id.present?
      sender_page_tokens[sender_id].include?(page_token)
    else
      inbox_page_tokens.include?(page_token)
    end
  end
end
