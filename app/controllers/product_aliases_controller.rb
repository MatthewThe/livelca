class ProductAliasesController < ApplicationController
  before_action :set_product_alias, only: [:show, :edit, :update, :destroy]

  # GET /product_aliases
  # GET /product_aliases.json
  def index
    @product_aliases = ProductAlias.all
  end

  # GET /product_aliases/1
  # GET /product_aliases/1.json
  def show
  end

  # GET /product_aliases/new
  def new
    @product_alias = ProductAlias.new
  end

  # GET /product_aliases/1/edit
  def edit
  end

  # POST /product_aliases
  # POST /product_aliases.json
  def create
    @product_alias = ProductAlias.new(product_alias_params)
    save_relations
    
    respond_to do |format|
      if @product_alias.save
        format.html { redirect_to @product_alias, notice: 'Product alias was successfully created.' }
        format.json { render :show, status: :created, location: @product_alias }
      else
        format.html { render :new }
        format.json { render json: @product_alias.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /product_aliases/1
  # PATCH/PUT /product_aliases/1.json
  def update
    save_relations
    
    respond_to do |format|
      if @product_alias.update(product_alias_params)
        format.html { redirect_to @product_alias, notice: 'Product alias was successfully updated.' }
        format.json { render :show, status: :ok, location: @product_alias }
      else
        format.html { render :edit }
        format.json { render json: @product_alias.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /product_aliases/1
  # DELETE /product_aliases/1.json
  def destroy
    @product_alias.destroy
    respond_to do |format|
      format.html { redirect_to product_aliases_url, notice: 'Product alias was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product_alias
      @product_alias = ProductAlias.find(params[:id])
    end
    
    def save_relations
      @product_alias.country = Country.find_or_create(product_alias_name_params[:country_name])
      @product_alias.product = Product.find_or_create(product_alias_name_params[:product_name])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def product_alias_params
      params.require(:product_alias).permit(:name)
    end
    
    def product_alias_name_params
      params.require(:product_alias).permit(:country_name, :product_name)
    end
end
