class RecipesController < ApplicationController
  before_action :authenticate_user!, only: [:edit, :update, :destroy]
  before_action :set_recipe, only: [:show, :edit, :update, :destroy]
  after_action :expire_cache, only: [:update, :update_all, :destroy]
  
  caches_page :table
  
  # GET /recipes
  # GET /recipes.json
  def index
    @recipe = Recipe.new
    @random_recipe = Recipe.get_random
    @tags = Tag.all.sort_by(&:weight).reverse.take(8) 
    # If all tags have a weight in the database, this is better:
    # @tags = Tag.order(weight: :desc).take(8)
  end
  
  # GET /recipes_table
  def table
    @recipes = Recipe.where(is_public: true)
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
    @country_consumption_name = @recipe.country_consumption.name
    respond_to_format
  end

  # GET /recipes/new
  def new
    @recipe = Recipe.new
    @recipe.servings = 4
    @country_consumption_name = ""
    if current_user
      @country_consumption_name = current_user.country.name
    end
    respond_to_format
  end

  # GET /recipes/1/edit
  def edit
    @country_consumption_name = @recipe.country_consumption.name
  end
  
  # POST /recipes
  # POST /recipes.json
  def create
    if recipe_ingredient_params[:ingredients_list]
      fill_form_from_ingredients_list
    elsif recipe_params[:url] && !ingredient_params[:product_name]
      fill_form_from_url
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
      
      save
    end
  end
  
  def save
    respond_to do |format|
      save_relations
      if @recipe.save
        expire_cache # the create action is overloaded, so only expire cache upon saving the recipe
        format.html { redirect_to @recipe, notice: 'Recipe was successfully created.' }
        format.json { render :show, status: :created, location: @recipe }
      else
        format.html { render :new }
        format.json { render json: @recipe.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /recipes/1
  # PATCH/PUT /recipes/1.json
  def update
    respond_to do |format|
      save_relations
      if @recipe.update(recipe_params)
        format.html { redirect_to @recipe, notice: 'Recipe was successfully updated.' }
        format.json { render :show, status: :ok, location: @recipe }
      else
        format.html { render :edit }
        format.json { render json: @recipe.errors, status: :unprocessable_entity }
      end
    end
  end
  
  # PATCH/PUT /recipes_update_all
  def update_all
    Recipe.find_each(&:save)
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
  
  def get_color
    render json: {:color => Recipe.co2_equiv_color_compute(params[:co2_equiv_kg].to_f)}
  end
  
  def tag
    @tag = Tag.from_param(params[:tag])
    @recipes = @tag.recipes.where(is_public: true)
    respond_to_format
  end
  

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_recipe
      @recipe = Recipe.where(id: Recipe.from_param(params[:id])).with_associations(:country_consumption, :ingredients => [:country_origin, :product => [:studies, :proxy => [:studies]]]).first
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def recipe_params
      params.require(:recipe).permit(:name, :servings, :description, :instructions, :url, :tags => [])
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
    
    def expire_cache
      expire_page :action => [:table], :format => 'json'
    end
    
    def save_relations
      if recipe_params[:tags]
        @recipe.tags = recipe_params[:tags].map{ |tag_name| Tag.find(tag_name) }
      else
        @recipe.tags = []
      end
    end
    
    def fill_form_from_ingredients_list
      @csv_table = parse_ingredients(recipe_ingredient_params[:ingredients_list])
      @country_consumption_name = recipe_name_params[:country_consumption_name]
      @recipe = Recipe.new(recipe_params)
      @recipe.user = current_user
      
      respond_to_format
    end
    
    def fill_form_from_url
      uri = URI(request.protocol + request.host + ':5000/recipes/')
      params = { :url => recipe_params[:url] }
      uri.query = URI.encode_www_form(params)

      res = Net::HTTP.get_response(uri)
      if res.is_a?(Net::HTTPSuccess) 
        response_body = JSON.parse(res.body)
        if response_body.size > 0
          ingredients_list = response_body['ingredients'].join("\n")
          @csv_table = parse_ingredients(ingredients_list)
          @country_consumption_name = "Unknown"
          if current_user
            @country_consumption_name = current_user.country.name
          end
          @recipe = Recipe.new({:name => response_body['title'], :servings => response_body['servings'], :instructions => "", :url => recipe_params[:url]})
          @recipe.user = current_user
          respond_to_format
          return
        end
      end
      
      @recipe = Recipe.new
      flash.now[:alert] = "Could not parse the ingredients from the specified URL"
      @random_recipe = Recipe.get_random
      
      respond_to_format
    end
    
    def parse_ingredients(ingredients_list)
      ingredients_table = []
      queries = []
      for row in ingredients_list.split("\n")
        weight, item = Ingredient.parse(row)
        if row.strip.length > 0
          ingredients_table.push({ item_name: row.strip, weight: weight, country_name: "Unknown" })
          Product.add_product_query(item, queries)
        end
      end
      
      results = Product.run_products_query(queries)
      ingredients_table.zip(results).each_with_index do |z, i|
        row, result = z
        product_name = ""
        if result.count > 0
          product_name = result.first['p.name']
        end
        ingredients_table[i][:product_name] = product_name
      end
      
      if ingredients_table.length == 0
        ingredients_table.push({ item_name: "", product_name: "", weight: 0, country_name: "Unknown" })
      end
      
      ingredients_table
    end
end
