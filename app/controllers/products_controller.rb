class ProductsController < ApplicationController
  before_action :authenticate_user!, :is_admin, only: [:new, :edit, :merge, :update, :destroy]
  before_action :set_product, only: [:show, :edit, :merge, :update, :destroy]
  
  caches_page :table, :graph_json
  
  # GET /products
  # GET /products.json
  def index
    if params[:search]
      @products = Product.search(params[:search])
      if @products.count == 1
        redirect_to @products[0]
      end
    end
    
    @product_count = Product.all.count
    @resource_count = Resource.all.count
    @study_count = Source.all.count
    @recipe_count = Recipe.all.count
    
    @latest_blog = Blog.where_not(published_at: nil).order(:published_at).last
    renderer = Redcarpet::Render::HTML.new(:link_attributes => Hash["target" => "_blank"], hard_wrap: true)
    markdown = Redcarpet::Markdown.new(renderer, extensions = {})
    @latest_blog_wiki = markdown.render(@latest_blog.post)
    
    @random_product = Product.as('q').order("(id(q) * (datetime.truncate('day', datetime()).epochMillis / 86400000)) % 1013").with_associations(:proxy, :studies, :subcategories).limit(1).first
    @random_recipe = Recipe.as('r').order("(id(r) * (datetime.truncate('day', datetime()).epochMillis / 86400000)) % 1013").with_associations(:ingredients => [:product => [:studies, :proxy => [:studies]]]).limit(1).first
    
    respond_to_format
  end
  
  def table
    @products = Product.all.with_associations(:studies, :proxy)
    respond_to do |format|
     format.json
    end
  end
  
  def graph
    respond_to do |format|
     format.html
    end
  end
  
  def graph_json
    @product_tree = Product.get_product_tree
    @products = Product.all.with_associations(:studies, :proxy).to_json(:methods => :co2_equiv_color)
    
    # tree with depth 1
    #@product = Product.find_by(name: "Food")
    #@products, @product_tree = @product.get_graph_nodes([])
    respond_to do |format|
     format.json
    end
  end
  
  def autocomplete
    @products = Product.search(params[:term])
    render json: @products.map{|p| {:label => p.name, :value => p.id}}
  end
  
  def autocomplete_name
    @products = Product.search(params[:term])
    render json: @products.map(&:name)
  end

  # GET /products/1
  # GET /products/1.json
  def show
    @supercategories = @product.get_super_categories
    renderer = Redcarpet::Render::HTML.new(:link_attributes => Hash["target" => "_blank"], hard_wrap: true)
    markdown = Redcarpet::Markdown.new(renderer, extensions = {})
    @wiki = markdown.render(@product.wiki)
    
    @products, @product_tree = @product.get_graph_nodes(@supercategories)
    
    respond_to_format
  end

  # GET /products/new
  def new
    @product = Product.new
  end

  # GET /products/1/edit
  def edit
  end
  
  # GET /products/1/edit
  def merge
  end

  # POST /products
  # POST /products.json
  def create
    @product = Product.new(product_params)
    save_relations
    
    respond_to do |format|
      if @product.save
        expire_cache
        format.html { redirect_to @product, notice: 'Product was successfully created.' }
        format.json { render :show, status: :created, location: @product }
      else
        format.html { render :new }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /products/1
  # PATCH/PUT /products/1.json
  def update
    if product_merge_params[:merge_product_name]
      respond_to do |format|
        if @product.merge_with(product_merge_params[:merge_product_name])
          expire_cache
          format.html { redirect_to @product, notice: 'Product was successfully merged.' }
          format.json { render :show, status: :ok, location: @product }
        else
          format.html { render :edit }
          format.json { render json: @product.errors, status: :unprocessable_entity }
        end
      end
      
    else
      save_relations
      respond_to do |format|
        if @product.update(product_params)
          expire_cache
          format.html { redirect_to @product, notice: 'Product was successfully updated.' }
          format.json { render :show, status: :ok, location: @product }
        else
          format.html { render :edit }
          format.json { render json: @product.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # DELETE /products/1
  # DELETE /products/1.json
  def destroy
    @product.destroy
    respond_to do |format|
      expire_cache
      format.html { redirect_to products_url, notice: 'Product was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  
  def expire_cache
    expire_page :action => [:table, :graph_json], :format => 'json'
  end
  
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product
      @product = Product.all.with_associations(:proxy, :studies, :subcategories).find(Product.from_param(params[:id]))
    end
    
    def save_relations
      @product.category = Product.find_or_create(product_name_params[:category_name])
      @product.proxy = Product.find_or_create(product_name_params[:proxy_name])
    end
    
    # Never trust parameters from the scary internet, only allow the white list through.
    def product_params
      params.require(:product).permit(:name, :wiki)
    end
    
    def product_name_params
      params.require(:product).permit(:category_name, :proxy_name)
    end
    
    def product_merge_params
      params.require(:product).permit(:merge_product_name)
    end
end
