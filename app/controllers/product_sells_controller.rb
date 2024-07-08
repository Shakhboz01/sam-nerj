class ProductSellsController < ApplicationController
  before_action :set_product_sell, only: %i[ show edit update destroy ]

  # GET /product_sells or /product_sells.json
  def index
    @q = ProductSell.ransack(params[:q])
    @product_sells = @q.result.includes(:product).order(id: :desc)
    @product_sells_data = @product_sells
    @rate = CurrencyRate.last.rate
    @product_sells = @product_sells.page(params[:page]).per(70)
  end

  # GET /product_sells/1 or /product_sells/1.json
  def show
    @q = ProductEntry.ransack(params[:q])
    @product_entries = @q.result.where(id: @product_sell.price_data.keys)
  end

  # GET /product_sells/new
  def new
    @product_sell = ProductSell.new(
      combination_of_local_product_id: params[:combination_of_local_product_id],
      sale_from_local_service_id: params[:sale_from_local_service_id],
      sale_from_service_id: params[:sale_from_service_id],
    )
  end

  # GET /product_sells/1/edit
  def edit
  end

  # POST /product_sells or /product_sells.json
  def create
    return handle_returning_pack(product_sell_params) unless product_sell_params['returning_pack'].to_i.zero?

    @product_sell = ProductSell.new(product_sell_params)

    unless (pack_name = product_sell_params[:pack_name]).empty?
      pack = Pack.create(
        name: pack_name, active: false, sell_price: product_sell_params[:sell_price],
        buy_price: product_sell_params[:sell_price],
        code: '1111',
        product_category: ProductCategory.last
      )
      @product_sell.pack_id = pack.id
    end

    respond_to do |format|
      if @product_sell.save
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update('product-sells-list', partial: 'product_sells/product_sells', locals: { shrink: true, sale: @product_sell.sale, product_sell: @product_sell, buyer: @product_sell.sale.buyer, product_sells: @product_sell.sale.product_sells }),
            turbo_stream.replace('sale-form', partial: 'sales/form', locals: { sale: @product_sell.sale })
          ]
        end
        format.html { redirect_to request.referrer }
        format.json { render :show, status: :created, location: @product_sell }
      else
        format.html { redirect_to request.referrer, notice: @product_sell.errors.messages.values.join("\n") }
        format.json { render json: @product_sell.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /product_sells/1 or /product_sells/1.json
  def update
    respond_to do |format|
      if @product_sell.update(product_sell_params)
        format.html { redirect_to product_sell_url(@product_sell) }
        format.json { render :show, status: :ok, location: @product_sell }
      else
        format.html { render :edit, product_sell: @product_sell, status: :unprocessable_entity }
        format.json { render json: @product_sell.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /product_sells/1 or /product_sells/1.json
  def destroy
    @product_sell.destroy
    respond_to do |format|
      format.html { redirect_to "#{request.referrer}?reload=true" }
      format.json { head :no_content }
    end
  end

  def ajax_sell_price_request
    return render json: ('Please fill forms') if product_sell_params[:pack_id].empty?

    pack = Pack.find(params[:pack_id])
    render json: {
      sell_price: pack.sell_price.to_i,
      buy_price: pack.buy_price.to_i
    }
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_product_sell
    @product_sell = ProductSell.find(params[:id])
  end

  def handle_returning_pack(prod_sell_params)
    sale = Sale.find(prod_sell_params['sale_id'])
    pack = Pack.find(prod_sell_params['pack_id'])
    product_sell = sale.product_sells.where(pack_id: pack.id).last
    return redirect_to request.referrer, notice: 'XATOLIK!!! Tovar mavjud emas' unless product_sell

    price_to_decrement = prod_sell_params['amount'].to_f * prod_sell_params['sell_price'].to_f
    product_sell.decrement!(:amount, prod_sell_params['amount'].to_f)
    sale.decrement!(:total_price, price_to_decrement)
    pack.increment!(:initial_remaining, prod_sell_params['amount'].to_f)
    redirect_to request.referrer, notice: 'Success'
  end

  # Only allow a list of trusted parameters through.
  def product_sell_params
    params.require(:product_sell).permit(
      :sale_from_local_service_id, :sale_id, :combination_of_local_product_id,
      :sell_price, :sell_price_in_uzs, :product_id, :total_profit, :amount, :payment_type, :pack_id, :barcode,
      :sell_by_piece, :pack_name, :returning_pack, :number_of_sizes, :width, :height
    )
  end
end
