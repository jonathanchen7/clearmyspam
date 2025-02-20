# frozen_string_literal: true

require "test_helper"

class InboxTest < ActiveSupport::TestCase
  test "#populate adds email threads to inbox, updates page token store, and returns new email count" do
    email_thread1 = build(:email_thread)
    email_thread2 = build(:email_thread)
    email_thread3 = build(:email_thread)
    inbox = Inbox.new("user_id")

    new_email_count = inbox.populate([email_thread1, email_thread2, email_thread3], page_token: "first_page_token")

    assert_equal 3, new_email_count
    assert_equal 3, inbox.size
    assert_equal "first_page_token", inbox.next_page_token

    email_thread4 = build(:email_thread)
    new_email_count = inbox.populate([email_thread1, email_thread4], page_token: "second_page_token")

    assert_equal 1, new_email_count
    assert_equal 4, inbox.size
    assert_equal "second_page_token", inbox.next_page_token
  end

  test "#protect_threads! updates email_threads and hash" do
    email_thread1 = create(:email_thread)
    email_thread2 = create(:email_thread, :protected)
    email_thread3 = create(:email_thread)
    inbox = setup_inbox([email_thread1, email_thread2, email_thread3])

    inbox.protect!([email_thread1, email_thread2])

    assert_equal true, email_thread1.reload.protected
    assert_equal true, email_thread2.reload.protected
    assert_equal false, email_thread3.reload.protected
  end

  test "#unprotect_threads! updates email_threads and hash" do
    email_thread1 = create(:email_thread)
    email_thread2 = create(:email_thread, :protected)
    email_thread3 = create(:email_thread, :protected)
    inbox = setup_inbox([email_thread1, email_thread2, email_thread3])

    inbox.unprotect!([email_thread1, email_thread2])

    assert_equal false, email_thread1.reload.protected
    assert_equal false, email_thread2.reload.protected
    assert_equal true, email_thread3.reload.protected
  end

  test "#archive_threads! updates email_threads and hash" do
    email_thread1 = create(:email_thread)
    email_thread2 = create(:email_thread)
    email_thread3 = create(:email_thread)

    inbox = setup_inbox([email_thread1, email_thread2, email_thread3])
    inbox.archive!([email_thread1, email_thread2])

    assert_equal true, email_thread1.reload.archived
    assert_equal true, email_thread2.reload.archived
    assert_equal false, email_thread3.reload.archived
    assert_equal 1, inbox.size
  end

  test "#trash_threads! updates email_threads and hash" do
    email_thread1 = create(:email_thread)
    email_thread2 = create(:email_thread)
    email_thread3 = create(:email_thread)
    inbox = setup_inbox([email_thread1, email_thread2, email_thread3])
    inbox.trash!([email_thread1, email_thread2])

    assert_equal true, email_thread1.reload.trashed
    assert_equal true, email_thread2.reload.trashed
    assert_equal false, email_thread3.reload.trashed
    assert_equal 1, inbox.size
  end

  test "#emails_by_sender returns email_threads grouped by sender" do
    personal_sender = build(:sender, :personal)
    old_business_sender = build(:sender, raw_sender: "Old Business Name <test@business.com>", as_of_date: 1.year.ago)
    new_business_sender = build(:sender, raw_sender: "New Business Name <test@business.com>", as_of_date: 1.day.ago)
    email_thread1 = build(:email_thread, sender: personal_sender)
    email_thread2 = build(:email_thread, :unread, sender: personal_sender)
    email_thread3 = build(:email_thread, sender: old_business_sender)
    email_thread4 = build(:email_thread, sender: old_business_sender)
    email_thread5 = build(:email_thread, sender: new_business_sender)
    inbox = setup_inbox([email_thread1, email_thread2, email_thread3, email_thread4, email_thread5])

    result = inbox.emails_by_sender(hide_personal: false)
    assert_equal 2, result.size
    assert_equal [new_business_sender, personal_sender], result.keys
    assert_equal [email_thread1, email_thread2].sort, result[personal_sender].sort
    assert_equal [email_thread3, email_thread4, email_thread5].sort, result[new_business_sender].sort
  end

  test "#sender_emails returns email_threads for the specified senders" do
    sender1, sender2 = build_list(:sender, 2)
    email_thread1 = build(:email_thread, sender: sender1, date: 1.year.ago)
    email_thread2 = build(:email_thread, :unread, sender: sender1, date: 1.week.ago)
    email_thread3 = build(:email_thread, :unread, sender: sender1, date: 1.day.ago)
    email_thread4 = build(:email_thread, sender: sender2)
    inbox = setup_inbox([email_thread1, email_thread2, email_thread3, email_thread4])

    assert_equal [email_thread3, email_thread2, email_thread1], inbox.sender_emails(sender1.id, sorted: true)
    assert_equal [email_thread4], inbox.sender_emails(sender2.id)
    assert_equal(
      [email_thread1, email_thread2, email_thread3, email_thread4].to_set,
      inbox.sender_emails(sender1.id, sender2.id, sorted: false).to_set
    )
  end

  private

  def setup_inbox(email_threads)
    inbox = Inbox.new("user_id")
    inbox.populate(email_threads, page_token: "next_page_token")

    inbox
  end
end
