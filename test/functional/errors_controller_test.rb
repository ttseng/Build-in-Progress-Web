require 'test_helper'

class ErrorsControllerTest < ActionController::TestCase
  test "should get not_found" do
    get :not_found
    assert_response :success
  end

  test "should get unacceptable" do
    get :unacceptable
    assert_response :success
  end

  test "should get internal_error" do
    get :internal_error
    assert_response :success
  end

end
