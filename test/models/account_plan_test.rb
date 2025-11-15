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
    assert_includes account_plan.errors.full_messages, "Daily disposal limit can't be blank"
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

  test "::stripe_price_id_for returns correct price ID for plan type" do
    assert_equal AccountPlan::WEEKLY_PRICE_ID, AccountPlan.stripe_price_id_for("weekly")
    assert_equal AccountPlan::MONTHLY_PRICE_ID, AccountPlan.stripe_price_id_for("monthly")

    assert_raises(RuntimeError) do
      AccountPlan.stripe_price_id_for("invalid")
    end
  end

  test "::plan_type_for returns correct plan type for price ID" do
    assert_equal "weekly", AccountPlan.plan_type_for(AccountPlan::WEEKLY_PRICE_ID)
    assert_equal "monthly", AccountPlan.plan_type_for(AccountPlan::MONTHLY_PRICE_ID)

    assert_raises(RuntimeError) do
      AccountPlan.plan_type_for("invalid_price_id")
    end
  end

  test "#end_subscription! sets subscription ended at time" do
    user = create(:user)
    pro_plan = create(:account_plan, :pro, user: user)

    freeze_time do
      pro_plan.end_subscription!
      assert_equal Time.current, pro_plan.stripe_subscription_ended_at
    end
  end

  test "#end_subscription! raises error for free plan" do
    user = create(:user)
    free_plan = create(:account_plan, :free, user: user)

    assert_raises(RuntimeError) do
      free_plan.end_subscription!
    end
  end

  test "#end_subscription! raises error for already ended plan" do
    user = create(:user)
    pro_plan = create(:account_plan, :pro, user: user)
    pro_plan.end_subscription!

    assert_raises(RuntimeError) do
      pro_plan.end_subscription!
    end
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

  test "#inactive_pro? returns true for ended pro plans" do
    user = create(:user)
    pro_plan = create(:account_plan, :pro, user: user)

    assert_not pro_plan.inactive_pro?

    pro_plan.end_subscription!
    assert pro_plan.inactive_pro?
  end

  test "#unpaid? returns true for free plans and false for pro plans" do
    user = create(:user)
    free_plan = create(:account_plan, :free, user: user)
    pro_plan = create(:account_plan, :pro, user: user)

    assert free_plan.unpaid?
    assert_not pro_plan.unpaid?
  end
end
