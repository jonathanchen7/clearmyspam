require "test_helper"

class FaqControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get faq_url
    assert_response :success
  end
end
