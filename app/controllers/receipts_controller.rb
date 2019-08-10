class ReceiptsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_receipt, only: [:show, :edit, :update, :destroy]

  # GET /receipts
  # GET /receipts.json
  def index
    @receipts = Receipt.where(user: current_user)
  end

  # GET /receipts/1
  # GET /receipts/1.json
  def show
    @purchase = Purchase.new
  end

  # GET /receipts/new
  def new
    @receipt = Receipt.new
    @country_consumption_name = current_user.country.name
  end

  # GET /receipts/1/edit
  def edit
  end
  
  
  def upload
    require 'rest-client'  
    require 'tempfile'
    uploaded_io = receipt_params[:receipt]
    ext = File.extname(uploaded_io.original_filename).downcase
    
    file = Tempfile.new(['receipt', ext])
    File.open(file, 'wb') do |file|
      file.write(uploaded_io.read)
    end
    @file = file
    
    purchase_table = []
    if [".png", ".jpg", ".jpeg", ".gif", ".tif", ".tiff", ".bmp"].include? ext 
      # uploaded_io.original_filename
      # Supported image file formats are png, jpg (jpeg), gif, tif (tiff) and bmp.
      data = RestClient.post('https://api.ocr.space/parse/image',
                                      { apikey: "f6a89dcb5688957",
                                        language: "swe",
                                        isOverlayRequired: false,
                                        isTable: true,
                                        file: file })
      require 'json'
      require 'csv'
      output = JSON.parse(data.body)
      parsedText = output["ParsedResults"][0]["ParsedText"]
      CSV.parse(parsedText, :col_sep => '\t', :quote_char => "Ƃ") do |row|
        row = row.shift.split("\t") unless row.blank?
        purchase_table.push({ item_name: row[0], product_name: row[0], weight: 1.0, country_name: "Unknown" })
      end
    elsif [".csv", ".tsv"].include? ext
      require 'csv'
      CSV.foreach(file) do |row|
        weight = 1.0
        country = "Unknown"
        if row.length > 1 and row[1].length > 0
          weight = row[1]
          if row.length > 2 and row[2].length > 0
            country = row[2]
          end
        end
        purchase_table.push({ item_name: row[0], product_name: get_product_name(row[0]), weight: weight, country_name: country })
      end
    end
    purchase_table
  end
  
  def get_product_name(item)
    results = Neo4j::ActiveBase.current_session.query("CALL db.index.fulltext.queryNodes('productNames', {item})
      YIELD node
      RETURN node.name
      LIMIT {limit}", item: item + "~", limit: 1)
    if results.count > 0
      results.first["node.name"]
    else
      ""
    end
  end

  # POST /receipts
  # POST /receipts.json
  def create
    if receipt_params[:receipt]
      @csv_table = upload
      respond_to do |format|
        format.html { render :table_edit }
      end
    else
      @receipt = Receipt.new(receipt_params)
      @receipt.country_consumption = Country.find_or_create(receipt_name_params[:country_consumption_name])
      @receipt.user = current_user

      respond_to do |format|
        if @receipt.save
          format.html { redirect_to @receipt, notice: 'Receipt was successfully created.' }
          format.json { render :show, status: :created, location: @receipt }
        else
          format.html { render :new }
          format.json { render json: @receipt.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PATCH/PUT /receipts/1
  # PATCH/PUT /receipts/1.json
  def update
    @receipt.country_consumption = Country.find_or_create(receipt_name_params[:country_consumption_name])
    
    respond_to do |format|
      if @receipt.update(receipt_params)
        format.html { redirect_to @receipt, notice: 'Receipt was successfully updated.' }
        format.json { render :show, status: :ok, location: @receipt }
      else
        format.html { render :edit }
        format.json { render json: @receipt.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /receipts/1
  # DELETE /receipts/1.json
  def destroy
    @receipt.destroy
    respond_to do |format|
      format.html { redirect_to receipts_url, notice: 'Receipt was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_receipt
      @receipt = Receipt.find(params[:id])
      @country_consumption_name = @receipt.country_consumption.name
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def receipt_params
      params.require(:receipt).permit(:date, :store, :receipt)
    end
    
    def receipt_name_params
      params.require(:receipt).permit(:country_consumption_name)
    end
end
