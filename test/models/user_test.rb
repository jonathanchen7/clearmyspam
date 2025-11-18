require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "#new validates email uniqueness" do
    user = create(:user)
    duplicate_user = build(:user, email: user.email)

    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors.full_messages, "Email has already been taken"
  end

  test ".unpaid filters users correctly based on account plan type" do
    free_user = create(:user)

    monthly_user = create(:user)
    create(:account_plan, :pro, user: monthly_user, plan_type: "monthly")

    weekly_user = create(:user)
    create(:account_plan, :pro, user: weekly_user, plan_type: "weekly")

    yearly_user = create(:user)
    create(:account_plan, :pro, user: yearly_user, plan_type: "yearly")

    user_with_ended_pro = create(:user)
    pro_plan = create(:account_plan, :pro, user: user_with_ended_pro)
    pro_plan.end_subscription!

    unpaid_user_ids = User.unpaid.map(&:id)

    assert_includes unpaid_user_ids, free_user.id
    assert_not_includes unpaid_user_ids, monthly_user.id
    assert_not_includes unpaid_user_ids, weekly_user.id
    assert_not_includes unpaid_user_ids, yearly_user.id
    assert_not_includes unpaid_user_ids, user_with_ended_pro.id
  end
end
