class RecipesController < ApplicationController
  before_action :authenticate_user!, only: [:new, :edit, :merge, :update, :destroy]
  before_action :set_recipe, only: [:show, :edit, :update, :destroy]
  
  # GET /recipes
  # GET /recipes.json
  def index
    respond_to_format
  end
  
  def table
    expires_in 24.hours, :public => true
    #if current_user
    #  @recipes = Recipe.where(user: current_user).with_associations(:ingredients => [:product => [:studies, :proxy => [:studies]]])
    #else
      @recipes = Recipe.where(is_public: true).with_associations(:ingredients => [:product => [:studies, :proxy => [:studies]]])
    #end
    respond_to do |format|
      format.json
    end
  end
  
  # GET /recipes/1
  # GET /recipes/1.json
  def show
    if params[:edit_ingredient]
      @ingredient = Ingredient.find(params[:edit_ingredient])
    else
      @ingredient = Ingredient.new
    end
    respond_to_format
  end

  # GET /recipes/new
  def new
    @recipe = Recipe.new
    @country_consumption_name = current_user.country.name
  end

  # GET /recipes/1/edit
  def edit
    @country_consumption_name = @recipe.country_consumption.name
  end

  def upload
    purchase_table = []
    queries = []
    for row in recipe_ingredient_params[:ingredients_list].split("\n")
      weight, item = Ingredient.parse(row)
      purchase_table.push({ item_name: row.strip, weight: weight, country_name: "Unknown" })
      Product.add_product_query(item, queries)
    end
    
    results = Product.run_products_query(queries)
    purchase_table.zip(results).each_with_index do |z, i|
      row, result = z
      product_name = ""
      if result.count > 0
        product_name = result.first['p.name']
      end
      purchase_table[i][:product_name] = product_name
    end
    purchase_table
  end
  
  # POST /recipes
  # POST /recipes.json
  def create
    if recipe_ingredient_params[:ingredients_list]
      @csv_table = upload
      @country_consumption_name = recipe_name_params[:country_consumption_name]
      @recipe = Recipe.new(recipe_params)
      @recipe.user = current_user
      
      respond_to do |format|
        format.html { render :table_edit }
      end
    else
      @recipe = Recipe.new(recipe_params)
      @recipe.country_consumption = Country.find_or_create(recipe_name_params[:country_consumption_name])
      @recipe.user = current_user
      
      if ingredient_params[:product_name]
        ingredients = ingredient_params.values.transpose.map { |s| Hash[ingredient_params.keys.zip(s)] }
        ingredients.each do |ingredient|
          weight, item_name = Ingredient.parse(ingredient["item_name"])
          if ingredient["product_name"].length > 0 and not ingredient["product_name"] == "None"
            @ingredient = Ingredient.new({:weight => ingredient["weight"]})
            #@ingredient.recipe = @recipe
            @ingredient.description = ingredient["item_name"]
            @ingredient.product = Product.find_or_create(ingredient["product_name"])
            @ingredient.country_origin = Country.find_or_create(ingredient["country_origin_name"])
            @recipe.ingredients << @ingredient
            
            @product_alias = ProductAlias.find_or_create(item_name)
            @product_alias.country = @recipe.country_consumption
            @product_alias.product = @ingredient.product
            if not @product_alias.save
              render :html => "Could not save product alias"
              return
            end
          elsif item_name.length > 0
            @product_alias = ProductAlias.find_or_create(item_name)
            @product_alias.country = @recipe.country_consumption
            @product_alias.product = Product.find_by(name: "None")
            if not @product_alias.save
              render :html => "Could not save product alias"
              return
            end
          end
        end
      end
      
      respond_to do |format|
        if @recipe.save
          format.html { redirect_to @recipe, notice: 'Recipe was successfully created.' }
          format.json { render :show, status: :created, location: @recipe }
        else
          format.html { render :new }
          format.json { render json: @recipe.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PATCH/PUT /recipes/1
  # PATCH/PUT /recipes/1.json
  def update
    respond_to do |format|
      if @recipe.update(recipe_params)
        format.html { redirect_to @recipe, notice: 'Recipe was successfully updated.' }
        format.json { render :show, status: :ok, location: @recipe }
      else
        format.html { render :edit }
        format.json { render json: @recipe.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /recipes/1
  # DELETE /recipes/1.json
  def destroy
    @recipe.destroy
    respond_to do |format|
      format.html { redirect_to recipes_url, notice: 'Recipe was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_recipe
      @recipe = Recipe.where(id: params[:id]).with_associations(:country_consumption, :ingredients => [:country_origin, :product => [:studies, :proxy => [:studies]]]).first
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def recipe_params
      params.require(:recipe).permit(:name, :servings)
    end
    
    def recipe_name_params
      params.require(:recipe).permit(:country_consumption_name)
    end
    
    def recipe_ingredient_params
      params.require(:recipe).permit(:ingredients_list)
    end
    
    def ingredient_params
      params.require(:recipe).permit(:item_name => [], :product_name => [], :weight => [], :country_origin_name => [])
    end
end
