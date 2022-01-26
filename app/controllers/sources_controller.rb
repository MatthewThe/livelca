class SourcesController < ApplicationController
  before_action :authenticate_user!, :is_admin, only: [:new, :edit, :update, :destroy]
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
      @source.product = Product.find(Product.from_param(params[:product_id]))
    end
    
    if params[:resource_id].present?
      @source.resource = Resource.find(Resource.from_param(params[:resource_id]))
      @source.weight = @source.resource.default_weight
    else
      @source.resource = Resource.new
    end
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
        format.html { redirect_to @source.resource, notice: 'Source was successfully created.' }
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
        format.html { redirect_to @source.resource, notice: 'Source was successfully updated.' }
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
    end
    
    def save_relations
      @source.resource = Resource.find_or_create(resource_params[:name], resource_params[:url], params[:weight])
      @source.product = Product.find_or_create(source_name_params[:product_name])
      @source.country_origin_id = Country.find_or_create(source_name_params[:country_origin_name])
      @source.country_consumption_id = Country.find_or_create(source_name_params[:country_consumption_name])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def source_params
      params.require(:source).permit(:co2_emission, :ch4_emission, :n2o_emission, :co2_equiv, :notes, :weight)
    end
    
    def source_name_params
      params.require(:source).permit(:product_name, :country_origin_name, :country_consumption_name)
    end
    
    def resource_params
      params.require(:resource).permit(:name, :url)
    end
end
