class ResourcesController < ApplicationController
  before_action :authenticate_user!, :is_admin, only: [:new, :edit, :update, :destroy]
  before_action :set_resource, only: [:show, :edit, :update, :destroy]

  # GET /resources
  # GET /resources.json
  def index
    respond_to_format
  end
  
  def table
    @resources = Resource.all
    respond_to do |format|
      format.json
    end
  end
  
  # GET /resources/1
  # GET /resources/1.json
  def show
    @notes = markdown(@resource.notes)
    
    respond_to_format
  end

  # GET /resources/new
  def new
    @resource = Resource.new
  end

  # GET /resources/1/edit
  def edit
  end

  # POST /resources
  # POST /resources.json
  def create
    @resource = Resource.new(resource_params)
    
    save_table
    
    respond_to do |format|
      if @resource.save
        format.html { redirect_to @resource, notice: 'Resource was successfully created.' }
        format.json { render :show, status: :created, location: @resource }
      else
        format.html { render :new }
        format.json { render json: @resource.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def save_table
    if table_params[:table]
      @csv_table = upload
      
       Neo4j::ActiveBase.current_session.transaction do |tx|
        @csv_table.each_with_index do |row, i|
          @source = Source.new
          @source.resource = @resource
          @source.co2_equiv = row[:co2_emission]
          @source.notes = row[:notes]
          @source.weight = @resource.default_weight
          @source.product = Product.find_or_create(row[:product_name])
          if !row[:product_category].nil? && @source.product.category.nil?
            @source.product.category = Product.find_or_create(row[:product_category])
          end
          if !row[:country_origin].nil?
            @source.country_origin_id = Country.find_or_create(row[:country_origin])
          else
            @source.country_origin_id = Country.find_or_create("Unknown")
          end
          if !row[:country_consumption].nil?
            @source.country_consumption_id = Country.find_or_create(row[:country_consumption])
          else
            @source.country_consumption_id = Country.find_or_create("Unknown")
          end
          @source.save
        end
      end
    end
  end
  
  def upload  
    require 'tempfile'
    uploaded_io = table_params[:table]
    ext = File.extname(uploaded_io.original_filename).downcase
    
    file = Tempfile.new(['resource', ext])
    File.open(file, 'wb') do |file|
      file.write(uploaded_io.read)
    end
    
    product_table = []
    queries = []
    if [".csv", ".tsv"].include? ext
      require 'csv'
      queries = []
      CSV.foreach(file,{:headers=>:first_row, :col_sep => "\t"}) do |row|
        product_table.push({ product_name: row[0], co2_emission: row[1], notes: row[2], product_category: row[3], country_origin: row[4], country_consumption: row[5] })
        #Product.add_product_query(row[0], queries)
      end
    end
    
    #results = Product.run_products_query(queries)
    #product_table.zip(results).each_with_index do |z, i|
    #  row, result = z
    #  product_name = ""
    #  if result.count > 0
    #    product_name = result.first['p.name']
    #  end
    #  product_table[i][:product_name] = product_name
    #end
    product_table
  end

  # PATCH/PUT /resources/1
  # PATCH/PUT /resources/1.json
  def update
    save_table
    
    respond_to do |format|
      if @resource.update(resource_params)
        format.html { redirect_to @resource, notice: 'Resource was successfully updated.' }
        format.json { render :show, status: :ok, location: @resource }
      else
        format.html { render :edit }
        format.json { render json: @resource.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /resources/1
  # DELETE /resources/1.json
  def destroy
    @resource.destroy
    respond_to do |format|
      format.html { redirect_to resources_url, notice: 'Resource was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_resource
      @resource = Resource.find(Resource.from_param(params[:id]))
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def resource_params
      params.require(:resource).permit(:name, :url, :default_weight, :notes)
    end
    
    def table_params
      params.require(:resource).permit(:table)
    end
end
