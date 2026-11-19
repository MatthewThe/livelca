class ResourcesController < ApplicationController
  before_action :authenticate_user!, :is_admin, only: [:new, :edit, :update, :destroy]
  before_action :set_resource, only: [:show, :edit, :update, :destroy, :product_table]

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
  
  # Server-side processing endpoint for the DataTables product table on the
  # resource page: only the requested page of sources is loaded.
  PRODUCT_TABLE_ORDER_COLUMNS = %w[product_name notes origin consumption].freeze
  PRODUCT_TABLE_MAX_LENGTH = 100

  def product_table
    start  = [params[:start].to_i, 0].max
    length = params[:length].to_i
    length = 25 if length <= 0
    length = [length, PRODUCT_TABLE_MAX_LENGTH].min

    search = params.dig(:search, :value).to_s.strip.downcase

    order_param  = params.dig(:order, "0") || {}
    order_column = PRODUCT_TABLE_ORDER_COLUMNS[order_param[:column].to_i] || PRODUCT_TABLE_ORDER_COLUMNS.first
    order_dir    = order_param[:dir].to_s.downcase == "desc" ? "DESC" : "ASC"

    # Start from the association query (and break) so the resource ID filter
    # stays on the first MATCH instead of being attached to an OPTIONAL MATCH.
    base = @resource.sources(:s).query.break
      .optional_match("(s)-[:STUDY_FOR]->(p:Product)")
      .optional_match("(s)-[:PRODUCED_IN]->(co:Country)")
      .optional_match("(s)-[:CONSUMED_IN]->(cc:Country)")
      .with("s, p, coalesce(p.name, '') AS product_name, coalesce(s.notes, '') AS notes, " \
            "coalesce(co.name, 'Unknown') AS origin, coalesce(cc.name, 'Unknown') AS consumption")

    @records_total = base.pluck("count(s)").first.to_i

    filtered = base
    if search.present?
      filtered = base
        .where("toLower(product_name) CONTAINS $search OR toLower(notes) CONTAINS $search " \
               "OR toLower(origin) CONTAINS $search OR toLower(consumption) CONTAINS $search")
        .params(search: search)
      @records_filtered = filtered.pluck("count(s)").first.to_i
    else
      @records_filtered = @records_total
    end

    @rows = filtered
      .order("#{order_column} #{order_dir}", "s.uuid")
      .skip(start)
      .limit(length)
      .pluck(:s, :p, :origin, :consumption)
    @draw = params[:draw].to_i

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
  
  def save_table
    return unless table_params[:table]
    @csv_table = upload

    # Each name is looked up at most once for the whole import
    products  = Hash.new { |h, name| h[name] = Product.find_or_create(name) }
    countries = Hash.new { |h, name| h[name] = Country.find_or_create(name) }

    @csv_table.each_slice(200) do |rows|
      ActiveGraph::Base.transaction do
        rows.each do |row|
          product = products[row[:product_name]]

          if row[:product_category].present? && product.category.blank?
            product.category = products[row[:product_category]]
          end

          if row[:co2_emission].present?
            source = Source.new
            source.resource  = @resource
            source.co2_equiv = row[:co2_emission]
            source.notes     = row[:notes]
            source.product   = product
            source.country_origin_id      = countries[row[:country_origin].presence || "Unknown"].id
            source.country_consumption_id = countries[row[:country_consumption].presence || "Unknown"].id
            source.weight = row[:weight].presence || @resource.default_weight
            source.save
          else
            if row[:proxy].present? && product.proxy.blank?
              product.proxy = products[row[:proxy]]
            end
          end
          product.save
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
      CSV.foreach(file, :headers=> true, :col_sep => "\t") do |row|
        product_table.push({ product_name: row[0], 
                             co2_emission: row[1], 
                             notes: row[2], 
                             product_category: row[3], 
                             country_origin: row[4], 
                             country_consumption: row[5],
                             weight: row[6],
                             proxy: row[7] })
      end
    end
    
    product_table
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_resource
      @resource = Resource.find(Resource.from_param(params[:id]))
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def resource_params
      params.require(:resource).permit(:name, :url, :notes, 
        :peer_reviewed, :num_products, :meta_study, :commissioned, 
        :year_of_study, :methodology_described, :source_reputation)
    end
    
    def table_params
      params.require(:resource).permit(:table)
    end
end
