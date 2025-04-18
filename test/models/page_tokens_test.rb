# frozen_string_literal: true

require "test_helper"

class PageTokensTest < ActiveSupport::TestCase
  test "#add stores inbox page tokens, accounting for duplicates and nil page_tokens" do
    page_tokens = PageTokens.new

    page_tokens.add("token1")
    assert page_tokens.inbox_page_tokens == ["token1"]

    page_tokens.add("token1")
    assert page_tokens.inbox_page_tokens == ["token1"]

    page_tokens.add("token2")
    assert page_tokens.inbox_page_tokens == %w[token1 token2]

    page_tokens.add(nil)
    assert page_tokens.inbox_page_tokens == %w[token1 token2 end_of_results]
  end

  test "#add stores sender page tokens, accounting for duplicates" do
    page_tokens = PageTokens.new

    page_tokens.add("token1", sender_id: "sender1")
    assert page_tokens.sender_page_tokens == { "sender1" => ["token1"] }

    page_tokens.add("token1", sender_id: "sender1")
    assert page_tokens.sender_page_tokens == { "sender1" => ["token1"] }

    page_tokens.add("token2", sender_id: "sender1")
    assert page_tokens.sender_page_tokens == { "sender1" => %w[token1 token2] }

    page_tokens.add(nil, sender_id: "sender1")
    assert page_tokens.sender_page_tokens == { "sender1" => %w[token1 token2 end_of_results] }
  end

  test "#final_page_fetched? returns true if the final inbox page has been fetched" do
    page_tokens = PageTokens.new
    assert_not page_tokens.final_page_fetched?

    page_tokens.add("token1")
    assert_not page_tokens.final_page_fetched?

    page_tokens.add("token2")
    assert_not page_tokens.final_page_fetched?

    page_tokens.add(nil)
    assert page_tokens.final_page_fetched?
  end

  test "#final_page_fetched? returns true if the final sender page has been fetched" do
    page_tokens = PageTokens.new

    page_tokens.add("token1", sender_id: "sender1")
    assert_not page_tokens.final_page_fetched?(sender_id: "sender1")

    page_tokens.add("token2", sender_id: "sender1")
    assert_not page_tokens.final_page_fetched?(sender_id: "sender1")

    page_tokens.add(nil, sender_id: "sender1")
    assert page_tokens.final_page_fetched?(sender_id: "sender1")
  end

  test "next_page_token returns the next inbox page token" do
    page_tokens = PageTokens.new

    page_tokens.add("token1")
    assert page_tokens.next_page_token == "token1"

    page_tokens.add("token2")
    assert page_tokens.next_page_token == "token2"

    page_tokens.add(nil)
    assert_raises ArgumentError, "Final page has already been fetched" do
      page_tokens.next_page_token
    end
  end

  test "next_page_token returns the next sender page token" do
    page_tokens = PageTokens.new

    page_tokens.add("token1", sender_id: "sender1")
    assert page_tokens.next_page_token(sender_id: "sender1") == "token1"

    page_tokens.add("token2", sender_id: "sender1")
    assert page_tokens.next_page_token(sender_id: "sender1") == "token2"

    page_tokens.add(nil, sender_id: "sender1")
    assert_raises ArgumentError, "Final page has already been fetched" do
      page_tokens.next_page_token(sender_id: "sender1")
    end
  end

  test "#for returns the correct page token" do
    page_tokens = PageTokens.new

    assert_nil page_tokens.for(page: 1)
    assert_nil page_tokens.for(page: 2)
    assert_nil page_tokens.for(page: 1, sender_id: "sender1")

    page_tokens.add("token1")
    page_tokens.add("token2")
    page_tokens.add(nil)

    page_tokens.add("sender_token1", sender_id: "sender1")
    page_tokens.add("sender_token2", sender_id: "sender1")

    assert page_tokens.for(page: 1) == "token1"
    assert page_tokens.for(page: 2) == "token2"
    assert page_tokens.for(page: 3) == "end_of_results"

    assert page_tokens.for(page: 1, sender_id: "sender1") == "sender_token1"
    assert page_tokens.for(page: 2, sender_id: "sender1") == "sender_token2"
  end
end
