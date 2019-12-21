class PurchasesController < ApplicationController
  before_action :set_purchase, only: [:show, :edit, :update, :destroy]

  # GET /purchases
  # GET /purchases.json
  def index
    @purchases = Purchase.all
  end

  # GET /purchases/1
  # GET /purchases/1.json
  def show
  end

  # GET /purchases/new
  def new
    @purchase = Purchase.new
  end

  # GET /purchases/1/edit
  def edit
  end

  # POST /purchases
  # POST /purchases.json
  def create
    @purchase = Purchase.new(purchase_params)
    @purchase.receipt = Receipt.find(purchase_params[:receipt])
    save_relations
    
    respond_to do |format|
      if @purchase.save
        format.html { redirect_to @purchase.receipt, notice: 'Purchase was successfully added.' }
        format.json { render :show, status: :created, location: @purchase }
      else
        format.html { render :new }
        format.json { render json: @purchase.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /purchases/1
  # PATCH/PUT /purchases/1.json
  def update
    save_relations
    respond_to do |format|
      if @purchase.update(purchase_params)
        format.html { redirect_to @purchase.receipt, notice: 'Purchase was successfully updated.' }
        format.json { render :show, status: :ok, location: @purchase }
      else
        format.html { render :edit }
        format.json { render json: @purchase.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /purchases/1
  # DELETE /purchases/1.json
  def destroy
    receipt = @purchase.receipt
    @purchase.destroy
    respond_to do |format|
      format.html { redirect_to receipt, notice: 'Purchase was successfully removed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_purchase
      @purchase = Purchase.find(params[:id])
    end
    
    def save_relations
      @purchase.product = Product.find_or_create(purchase_name_params[:product_name])
      @purchase.country_origin = Country.find_or_create(purchase_name_params[:country_origin_name])
    end
    
    # Never trust parameters from the scary internet, only allow the white list through.
    def purchase_params
      params.require(:purchase).permit(:weight, :receipt)
    end
    
    def purchase_name_params
      params.require(:purchase).permit(:product_name, :country_origin_name)
    end
    
end
