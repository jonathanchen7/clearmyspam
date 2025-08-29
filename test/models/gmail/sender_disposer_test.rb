# frozen_string_literal: true

require "test_helper"

class Gmail::SenderDisposerTest < ActiveSupport::TestCase
  def setup
    @user = create(:user)
    @sender1 = build(:sender, email: "sender1@example.com")
    @sender2 = build(:sender, email: "sender2@example.com")
    @sender3 = build(:sender, email: "sender3@example.com")
  end

  test "#initialize creates a new sender disposer with empty result" do
    senders = [@sender1, @sender2]
    disposer = Gmail::SenderDisposer.new(@user, senders)

    assert_equal @user, disposer.user
    assert_equal [@sender1, @sender2], disposer.senders
    assert_instance_of Gmail::SenderDisposer::Result, disposer.result
    assert_empty disposer.result.disposed_email_ids
    assert_empty disposer.result.fully_disposed_sender_ids
    assert_empty disposer.result.partially_disposed_senders
  end

  test "#initialize removes duplicate senders" do
    senders = [@sender1, @sender1, @sender2]
    disposer = Gmail::SenderDisposer.new(@user, senders)

    assert_equal [@sender1, @sender2], disposer.senders
  end

  test "#dispose_all! handles various disposal scenarios" do
    # Mock different scenarios: no emails, fully disposed, partially disposed
    @sender1.stubs(:fetch_actionable_email_ids!).returns([])
    @sender2.stubs(:fetch_actionable_email_ids!).returns(["email1", "email2"])
    @sender2.stubs(:email_count).returns(2)
    @sender3.stubs(:fetch_actionable_email_ids!).returns(["email3"])
    @sender3.stubs(:email_count).returns(10)

    senders = [@sender1, @sender2, @sender3]
    disposer = Gmail::SenderDisposer.new(@user, senders)

    # Mock Email.dispose_all! to avoid actual disposal
    Email.expects(:dispose_all!).with(@user, vendor_ids: ["email1", "email2", "email3"])

    result = disposer.dispose_all!

    assert_equal ["email1", "email2", "email3"], result.disposed_email_ids
    assert_equal [@sender2.id], result.fully_disposed_sender_ids
    assert_equal({ @sender3 => 1 }, result.partially_disposed_senders)
  end

  test "#dispose_all! handles no actionable emails" do
    # Mock all senders to return no actionable emails
    @sender1.stubs(:fetch_actionable_email_ids!).returns([])
    @sender2.stubs(:fetch_actionable_email_ids!).returns([])
    @sender3.stubs(:fetch_actionable_email_ids!).returns([])

    senders = [@sender1, @sender2, @sender3]
    disposer = Gmail::SenderDisposer.new(@user, senders)

    # Mock Email.dispose_all! to avoid actual disposal
    Email.expects(:dispose_all!).with(@user, vendor_ids: [])

    result = disposer.dispose_all!

    assert_empty result.disposed_email_ids
    assert_empty result.fully_disposed_sender_ids
    assert_empty result.partially_disposed_senders
  end

  test "#dispose_all! handles multiple partially disposed senders" do
    # Mock senders where multiple are partially disposed
    @sender1.stubs(:fetch_actionable_email_ids!).returns(["email1"])
    @sender1.stubs(:email_count).returns(5) # Partially disposed
    @sender2.stubs(:fetch_actionable_email_ids!).returns(["email2", "email3"])
    @sender2.stubs(:email_count).returns(10) # Partially disposed
    @sender3.stubs(:fetch_actionable_email_ids!).returns(["email4", "email5", "email6"])
    @sender3.stubs(:email_count).returns(3) # Fully disposed

    senders = [@sender1, @sender2, @sender3]
    disposer = Gmail::SenderDisposer.new(@user, senders)

    # Mock Email.dispose_all! to avoid actual disposal
    Email.expects(:dispose_all!).with(@user, vendor_ids: ["email1", "email2", "email3", "email4", "email5", "email6"])

    result = disposer.dispose_all!

    assert_equal ["email1", "email2", "email3", "email4", "email5", "email6"], result.disposed_email_ids
    assert_equal [@sender3.id], result.fully_disposed_sender_ids
    assert_equal({ @sender1 => 1, @sender2 => 2 }, result.partially_disposed_senders)
  end

  test "#dispose_all! returns the result object" do
    @sender1.stubs(:fetch_actionable_email_ids!).returns(["email1"])
    @sender1.stubs(:email_count).returns(1)

    senders = [@sender1]
    disposer = Gmail::SenderDisposer.new(@user, senders)

    # Mock Email.dispose_all! to avoid actual disposal
    Email.expects(:dispose_all!).with(@user, vendor_ids: ["email1"])

    result = disposer.dispose_all!

    assert_instance_of Gmail::SenderDisposer::Result, result
    assert_equal ["email1"], result.disposed_email_ids
    assert_equal [@sender1.id], result.fully_disposed_sender_ids
  end
end
