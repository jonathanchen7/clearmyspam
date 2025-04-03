require "test_helper"

class PricingControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "should get index" do
    get pricing_url
    assert_response :success
  end

  test "buttons show the correct CTAs when user is not logged in" do
    get pricing_url
    assert_select "button", { count: 3, text: "Login to get started" }
  end
end
