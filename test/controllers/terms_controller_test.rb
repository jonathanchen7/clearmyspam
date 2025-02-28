require "test_helper"

class TermsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get terms_url
    assert_response :success
  end
end
