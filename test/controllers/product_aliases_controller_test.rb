require 'test_helper'

class ProductAliasesControllerTest < ActionController::TestCase
  setup do
    @product_alias = product_aliases(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:product_aliases)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create product_alias" do
    assert_difference('ProductAlias.count') do
      post :create, product_alias: { country_id: @product_alias.country_id, name: @product_alias.name, product_id: @product_alias.product_id }
    end

    assert_redirected_to product_alias_path(assigns(:product_alias))
  end

  test "should show product_alias" do
    get :show, id: @product_alias
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @product_alias
    assert_response :success
  end

  test "should update product_alias" do
    patch :update, id: @product_alias, product_alias: { country_id: @product_alias.country_id, name: @product_alias.name, product_id: @product_alias.product_id }
    assert_redirected_to product_alias_path(assigns(:product_alias))
  end

  test "should destroy product_alias" do
    assert_difference('ProductAlias.count', -1) do
      delete :destroy, id: @product_alias
    end

    assert_redirected_to product_aliases_path
  end
end
