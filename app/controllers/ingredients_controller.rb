class IngredientsController < ApplicationController
  before_action :authenticate_user!, except: [:json]
  before_action :set_ingredient, only: [:show, :edit, :update, :destroy]

  # GET /ingredients
  # GET /ingredients.json
  def index
    @ingredients = Ingredient.all
  end

  # GET /ingredients/1
  # GET /ingredients/1.json
  def show
  end

  # GET /ingredients/new
  def new
    @ingredient = Ingredient.new
  end

  # GET /ingredients/1/edit
  def edit
  end

  # POST /ingredients
  # POST /ingredients.json
  def create
    @ingredient = Ingredient.new(ingredient_params)
    @ingredient.recipe = Recipe.find(ingredient_params[:recipe])
    save_relations
    
    respond_to do |format|
      if @ingredient.save
        format.html { redirect_to @ingredient.recipe, notice: 'Ingredient was successfully added.' }
        format.json { render :show, status: :created, location: @ingredient }
      else
        format.html { render :new }
        format.json { render json: @ingredient.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ingredients/1
  # PATCH/PUT /ingredients/1.json
  def update
    respond_to do |format|
      save_relations
      if @ingredient.update(ingredient_params)
        format.html { redirect_to @ingredient.recipe, notice: 'Ingredient was successfully updated.' }
        format.json { render :show, status: :ok, location: @ingredient }
      else
        format.html { render :edit }
        format.json { render json: @ingredient.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ingredients/1
  # DELETE /ingredients/1.json
  def destroy
    recipe = @ingredient.recipe
    @ingredient.destroy
    respond_to do |format|
      if recipe
        format.html { redirect_to recipe, notice: 'Ingredient was successfully removed.' }
        format.json { head :no_content }
      else
        format.html { redirect_to ingredients_path, notice: 'Ingredient was successfully removed.' }
        format.json { head :no_content }
      end
    end
  end
  
  def json
    @ingredient = Ingredient.new({:weight => params[:weight]})
    @ingredient.product = Product.find_by(name: params[:name])
    if not @ingredient.product
      @ingredient.product = Product.find_by(name: "Food")
      product_name = params[:name]
    else
      product_name = @ingredient.product.name
    end
    servings = params[:servings].to_f
    render json: {:idx => params[:idx], :label => product_name, :value => @ingredient.co2_equiv, :color => @ingredient.co2_equiv_color(servings) }
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ingredient
      @ingredient = Ingredient.find(params[:id])
    end
    
    def save_relations
      @ingredient.product = Product.find_or_create(ingredient_name_params[:product_name])
      @ingredient.country_origin = Country.find_or_create(ingredient_name_params[:country_origin_name])
    end
    
    # Never trust parameters from the scary internet, only allow the white list through.
    def ingredient_params
      params.require(:ingredient).permit(:weight, :recipe, :description)
    end
    
    def ingredient_name_params
      params.require(:ingredient).permit(:product_name, :country_origin_name)
    end
end
