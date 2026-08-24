require "test_helper"

class PricingControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "should get index" do
    get pricing_url
    assert_response :success
  end

  test "links show the correct CTAs when user is not logged in" do
    get pricing_url
    assert_select "a", { count: 3, text: "Get started for free" }
  end

  test "signed in users cannot checkout new upgrades" do
    user = create(:user)
    sign_in user

    post pricing_checkout_url, params: { type: "monthly" }

    assert_response :forbidden

    json_response = JSON.parse(response.body)
    assert_equal false, json_response["success"]
    assert_match "temporarily unavailable", json_response["error"]
  end

  test "signed in free users see paused upgrade buttons on pricing page" do
    user = create(:user)
    sign_in user

    get pricing_url

    assert_response :success
    assert_select "button", text: "Upgrades Paused", count: 2
    assert_select "button[data-action='click->pricing#checkout']", count: 0
  end
end
