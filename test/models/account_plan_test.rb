require "test_helper"

class AccountPlanTest < ActiveSupport::TestCase
  test "it validates plan type" do
    user = create(:user)
    account_plan = AccountPlan.new(plan_type: "invalid", user: user)
    assert_not account_plan.valid?
    assert_includes account_plan.errors.full_messages, "Plan type is not included in the list"
  end

  test "it validates thread limit" do
    user = create(:user)
    account_plan = AccountPlan.new(plan_type: "trial", user: user)
    assert_not account_plan.valid?
    assert_includes account_plan.errors.full_messages, "Thread disposal limit can't be blank"
  end

  test "it validates stripe subscription id" do
    user = create(:user)
    account_plan = AccountPlan.new(plan_type: "monthly", user: user)
    assert_not account_plan.valid?
    assert_includes account_plan.errors.full_messages, "Stripe subscription can't be blank"
  end

  test "it validates there are no other active pro plans" do
    user = create(:user)
    pro_account_plan = create(:account_plan, :pro, user: user)
    assert pro_account_plan.valid?

    new_account_plan = build(:account_plan, :free, user: user.reload)
    assert_not new_account_plan.valid?
    assert_includes new_account_plan.errors.full_messages, "User already has an active pro plan"

    new_account_plan = build(:account_plan, :pro, user: user.reload)
    assert_not new_account_plan.valid?
    assert_includes new_account_plan.errors.full_messages, "User already has an active pro plan"

    pro_account_plan.end_subscription!
    user.reload
    assert new_account_plan.valid?
  end

  test "#active_pro? returns true iff the account plan is paid and not ended" do
    user = create(:user)
    free_account_plan = create(:account_plan, :free, user: user)
    assert_not free_account_plan.active_pro?

    pro_account_plan = create(:account_plan, :pro, user: user)
    assert pro_account_plan.active_pro?

    pro_account_plan.end_subscription!
    assert_not pro_account_plan.active_pro?
  end
end
