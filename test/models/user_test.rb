require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "#new validates email uniqueness" do
    user = create(:user)
    duplicate_user = build(:user, email: user.email)

    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors.full_messages, "Email has already been taken"
  end
end
