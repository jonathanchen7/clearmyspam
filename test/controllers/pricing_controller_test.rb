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
end
