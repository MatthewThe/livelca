class ReceiptsController < ApplicationController
  before_action :authenticate_user!, :is_admin, only: [:show, :edit, :update, :destroy]
  before_action :set_receipt, only: [:show, :edit, :update, :destroy]

  # GET /receipts
  # GET /receipts.json
  def index
    @receipts = Receipt.where(user: current_user)
  end

  # GET /receipts/1
  # GET /receipts/1.json
  def show
    if params[:edit_purchase]
      @purchase = Purchase.find(params[:edit_purchase])
    else
      @purchase = Purchase.new
    end
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
    uploaded_io = receipt_name_params[:receipt]
    ext = File.extname(uploaded_io.original_filename).downcase
    
    file = Tempfile.new(['receipt', ext])
    File.open(file, 'wb') do |file|
      file.write(uploaded_io.read)
    end
    
    purchase_table = []
    queries = []
    if [".png", ".jpg", ".jpeg", ".gif", ".tif", ".tiff", ".bmp"].include? ext 
      # uploaded_io.original_filename
      # Supported image file formats are png, jpg (jpeg), gif, tif (tiff) and bmp.
      file_size = File.size(file)
      if file_size > 1e6
        width, height = FastImage.size(file)
        ratio = Math.sqrt(file_size / 9e5)
        new_width, new_height = [(width / ratio).round, (height / ratio).round]
        require 'fastimage_resize'
        file = FastImage.resize(file, new_width, new_height)
      end
      data = RestClient.post('https://api.ocr.space/parse/image',
                                      { apikey: "f6a89dcb5688957",
                                        language: "swe",
                                        isOverlayRequired: false,
                                        isTable: true,
                                        file: file })
      require 'json'
      require 'csv'
      output = JSON.parse(data.body)
      if output["OCRExitCode"] != 1
        @receipt = Receipt.new(receipt_params)
        @receipt.errors[:receipt] = "Error processing file: #{output['ErrorMessage']}"
        @country_consumption_name = receipt_name_params[:country_consumption_name]
        return nil
      else
        parsedText = output["ParsedResults"][0]["ParsedText"]
        
        CSV.parse(parsedText, :col_sep => '\t', :quote_char => "Ƃ") do |row|
          row = row.shift.split("\t") unless row.blank?
          item = row[0]
          purchase_table.push({ item_name: item, weight: 1.0, country_name: "Unknown" })
          Product.add_product_query(item, queries)
        end
      end
    elsif [".csv", ".tsv"].include? ext
      require 'csv'
      queries = []
      CSV.foreach(file) do |row|
        weight = 1.0
        country = "Unknown"
        if row.length > 1 and row[1].length > 0
          weight = row[1]
          if row.length > 2 and row[2].length > 0
            country = row[2]
          end
        end
        purchase_table.push({ item_name: row[0], weight: weight, country_name: country })
        Product.add_product_query(row[0], queries)
      end
    end
    
    results = Product.run_products_query(queries)
    purchase_table.zip(results).each_with_index do |z, i|
      row, result = zip
      purchase_table[i][:product_name] = result
    end
    purchase_table
  end

  # POST /receipts
  # POST /receipts.json
  def create
    if receipt_name_params[:receipt]
      @csv_table = upload
      @receipt = Receipt.new(receipt_params)
      @country_consumption_name = receipt_name_params[:country_consumption_name]
      if @csv_table
        respond_to do |format|
          format.html { render :table_edit }
        end
      else
        respond_to do |format|
          format.html { render :new }
        end
      end
    else
      @receipt = Receipt.new(receipt_params)
      @receipt.country_consumption = Country.find_or_create(receipt_name_params[:country_consumption_name])
      @receipt.user = current_user

      respond_to do |format|
        if @receipt.save
          if purchase_params[:product_name]
            purchases = purchase_params.values.transpose.map { |s| Hash[purchase_params.keys.zip(s)] }
            purchases.each do |purchase|
              if purchase["product_name"].length > 0 and not purchase["product_name"] == "None"
                @purchase = Purchase.new({:weight => purchase["weight"]})
                @purchase.receipt = @receipt
                @purchase.product = Product.find_or_create(purchase["product_name"])
                @purchase.country_origin = Country.find_or_create(purchase["country_origin_name"])
                if not @purchase.save
                  render :html => "Could not save purchase"
                  return
                end
                
                @product_alias = ProductAlias.find_or_create(purchase["item_name"])
                @product_alias.country = @receipt.country_consumption
                @product_alias.product = @purchase.product
                if not @product_alias.save
                  render :html => "Could not save product alias"
                  return
                end
              elsif purchase["item_name"].length > 0
                @product_alias = ProductAlias.find_or_create(purchase["item_name"])
                @product_alias.country = @receipt.country_consumption
                @product_alias.product = Product.find_by(name: "None")
                if not @product_alias.save
                  render :html => "Could not save product alias"
                  return
                end
              end
            end
          end
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
      params.require(:receipt).permit(:date, :store)
    end
    
    def receipt_name_params
      params.require(:receipt).permit(:country_consumption_name, :receipt)
    end
    
    def purchase_params
      params.require(:receipt).permit(:item_name => [], :product_name => [], :weight => [], :country_origin_name => [])
    end
end
