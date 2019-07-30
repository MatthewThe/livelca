require 'test_helper'

class SourcesControllerTest < ActionController::TestCase
  setup do
    @source = sources(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:sources)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create source" do
    assert_difference('Source.count') do
      post :create, source: { ch4_emission: @source.ch4_emission, co2_emission: @source.co2_emission, co2_equiv: @source.co2_equiv, country_consumption_id: @source.country_consumption_id, country_origin_id: @source.country_origin_id, n2o_emission: @source.n2o_emission, name: @source.name, notes: @source.notes, url: @source.url, weight: @source.weight }
    end

    assert_redirected_to source_path(assigns(:source))
  end

  test "should show source" do
    get :show, id: @source
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @source
    assert_response :success
  end

  test "should update source" do
    patch :update, id: @source, source: { ch4_emission: @source.ch4_emission, co2_emission: @source.co2_emission, co2_equiv: @source.co2_equiv, country_consumption_id: @source.country_consumption_id, country_origin_id: @source.country_origin_id, n2o_emission: @source.n2o_emission, name: @source.name, notes: @source.notes, url: @source.url, weight: @source.weight }
    assert_redirected_to source_path(assigns(:source))
  end

  test "should destroy source" do
    assert_difference('Source.count', -1) do
      delete :destroy, id: @source
    end

    assert_redirected_to sources_path
  end
end
