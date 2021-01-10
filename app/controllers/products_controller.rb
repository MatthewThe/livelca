class ProductsController < ApplicationController
  before_action :authenticate_user!, :is_admin, only: [:new, :edit, :merge, :update, :destroy]
  before_action :set_product, only: [:show, :edit, :merge, :update, :destroy]

  # GET /products
  # GET /products.json
  def index
    if params[:search]
      @products = Product.search(params[:search])
      if @products.count == 1
        redirect_to @products[0]
      end
    else
      @products = Product.all
    end
  end
  
  def table
    expires_in 1.hour, :public => true
    @products = Product.all.with_associations(:studies, :proxy)
    respond_to do |format|
     format.json
    end
  end
  
  def graph
    expires_in 1.hour, :public => true
    if request.format == :json
      @product_tree = Product.get_product_tree
      @products = Product.all.with_associations(:studies, :proxy).to_json(:methods => :co2_equiv_color)
      
      # tree with depth 1
      #@product = Product.find_by(name: "Food")
      #@products, @product_tree = @product.get_graph_nodes([])
      
      # slow query
      #@products = (@product.subcategories + [@product]).map{|sc| {:product => sc.attributes.merge(:co2_equiv_color => sc.co2_equiv_color)}}
      #@product_tree = []
      #@product_tree.push({:product => @product.attributes.merge(:subcategories => @product.subcategories.map{|p| p.attributes})})
    end
    respond_to do |format|
     format.json
     format.html
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
    renderer = Redcarpet::Render::HTML.new(no_links: true, hard_wrap: true)
    markdown = Redcarpet::Markdown.new(renderer, extensions = {})
    @wiki = markdown.render(@product.wiki)
    
    @products, @product_tree = @product.get_graph_nodes(@supercategories)
    
    respond_to do |format|
      format.js {render layout: false}
      format.html {render :index, layout: true}
    end
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
      format.html { redirect_to products_url, notice: 'Product was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product
      @product = Product.all.with_associations(:proxy, :studies, :subcategories).find(params[:id])
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
