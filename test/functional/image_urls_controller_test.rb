require 'test_helper'

class ImageUrlsControllerTest < ActionController::TestCase
  setup do
    @image_url = image_urls(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:image_urls)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create image_url" do
    assert_difference('ImageUrl.count') do
      post :create, :image_url => { :project_id => @image_url.project_id, :step_id => @image_url.step_id, :url => @image_url.url }
    end

    assert_redirected_to image_url_path(assigns(:image_url))
  end

  test "should show image_url" do
    get :show, :id => @image_url
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @image_url
    assert_response :success
  end

  test "should update image_url" do
    put :update, :id => @image_url, :image_url => { :project_id => @image_url.project_id, :step_id => @image_url.step_id, :url => @image_url.url }
    assert_redirected_to image_url_path(assigns(:image_url))
  end

  test "should destroy image_url" do
    assert_difference('ImageUrl.count', -1) do
      delete :destroy, :id => @image_url
    end

    assert_redirected_to image_urls_path
  end
end
