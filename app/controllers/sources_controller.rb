class SourcesController < ApplicationController
  before_action :set_source, only: [:show, :edit, :update, :destroy]

  # GET /sources
  # GET /sources.json
  def index
    @sources = Source.all
  end

  # GET /sources/1
  # GET /sources/1.json
  def show
  end
  
  # GET /sources/new
  def new
    @source = Source.new
    if params[:product_id]
      @source.product = Product.find_by(id: params[:product_id])
    end
    get_product_name
  end

  # GET /sources/1/edit
  def edit
  end

  # POST /sources
  # POST /sources.json
  def create
    @source = Source.new(source_params)
    save_relations
    
    respond_to do |format|
      if @source.save
        format.html { redirect_to @source, notice: 'Source was successfully created.' }
        format.json { render :show, status: :created, location: @source }
      else
        format.html { render :new }
        format.json { render json: @source.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /sources/1
  # PATCH/PUT /sources/1.json
  def update
    save_relations
    
    respond_to do |format|
      if @source.update(source_params)
        format.html { redirect_to @source, notice: 'Source was successfully updated.' }
        format.json { render :show, status: :ok, location: @source }
      else
        format.html { render :edit }
        format.json { render json: @source.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sources/1
  # DELETE /sources/1.json
  def destroy
    @source.destroy
    respond_to do |format|
      format.html { redirect_to sources_url, notice: 'Source was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_source
      @source = Source.find(params[:id])
      
      get_product_name
    
      @country_origin_name = ""
      country_origin = Country.find_by(id: @source.country_origin_id)
      if country_origin
        @country_origin_name = country_origin.name
      end
        
      @country_consumption_name = ""
      country_consumption = Country.find_by(id: @source.country_consumption_id)
      if country_consumption
        @country_consumption_name = country_consumption.name
      end
    end
    
    def get_product_name
      @product_name = Product.get_name(@source.product_id)
    end
    
    def save_relations
      product = Product.find_by(name: source_name_params[:product_name])
      if !product
        product = Product.new(name: source_name_params[:product_name])
        product.save
      end
      @source.product = product
      
      country_origin = Country.find_by(name: source_name_params[:country_origin_name])
      if !country_origin
        country_origin = Country.new(name: source_name_params[:country_origin_name])
        country_origin.save
      end
      @source.country_origin_id = country_origin
      
      country_consumption = Country.find_by(name: source_name_params[:country_consumption_name])
      if !country_consumption
        country_consumption = Country.new(name: source_name_params[:country_consumption_name])
        country_consumption.save
      end
      @source.country_consumption_id = country_consumption
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def source_params
      params.require(:source).permit(:name, :url, :co2_emission, :ch4_emission, :n2o_emission, :co2_equiv, :notes, :weight)
    end
    
    def source_name_params
      params.require(:source).permit(:product_name, :country_origin_name, :country_consumption_name)
    end
end
