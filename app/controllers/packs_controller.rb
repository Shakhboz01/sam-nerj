class PacksController < ApplicationController
  before_action :set_pack, only: %i[ product_entries toggle_active show edit update destroy calculate_product_remaining update_buy_price]

  def toggle_active
    @pack.toggle(:active).save
    redirect_to packs_url, notice: "Successfully updated"
  end

  # GET /packs or /packs.json
  def index
    @q = Pack.all.ransack(params[:q])
    @packs = @q.result.order(active: :desc).order(name: :asc)
    @all_packs = @packs.where(active: true).where('initial_remaining > 0')
    @packs_data = @packs
    @packs = @packs.page(params[:page]).per(40)
    respond_to do |format|
      format.html
      format.xlsx
    end
  end

  # GET /packs/1 or /packs/1.json
  def show
  end

  # GET /packs/new
  def new
    @random_code = Product.generate_code
    @random_barcode = Product.generate_barcode
    @pack = Pack.new
  end

  # GET /packs/1/edit
  def edit
    @random_code = @pack.code
    @random_barcode = @pack.barcode
  end

  # POST /packs or /packs.json
  def create
    @pack = Pack.new(pack_params)
    delivery = DeliveryFromCounterparty.where(id: pack_params['delivery_id']).last

    respond_to do |format|
      if @pack.save
        if !pack_params['delivery_id'].empty?
          format.html { redirect_to delivery_from_counterparty_url(delivery, pack_id: @pack.id), notice: "Pack was successfully created." }
        else
          format.html { redirect_to packs_url, notice: "Pack was successfully created." }
        end

        format.json { render :show, status: :created, location: @pack }
      else
        format.html { redirect_to request.referrer, notice: @pack.errors.messages.values.join(' | ') }
        format.json { render json: @pack.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /packs/1 or /packs/1.json
  def update
    respond_to do |format|
      if @pack.update(pack_params)
        format.html { redirect_to packs_url, notice: "Pack was successfully updated." }
        format.json { render :show, status: :ok, location: @pack }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @pack.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /packs/1 or /packs/1.json
  def destroy
    @pack.destroy

    respond_to do |format|
      format.html { redirect_to packs_url, notice: "Pack was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def filtered_packs
    code_value = params[:code_value].downcase.strip
    @filtered_packs = Pack.where("lower(code) LIKE ? OR lower(barcode) LIKE ?", "%#{code_value}%", "%#{code_value}%")
    respond_to do |format|
      format.js # assuming you have a corresponding js.erb file for the response
    end
  end

  def calculate_product_remaining
    render json: { calculate_product_remaining: @pack.initial_remaining }
  end

  def update_buy_price
    Packs::UpdateBuyPrice.run!(pack: @pack)
    redirect_to request.referrer, notice: 'Narx o\'zgartirildi'
  end

  def product_entries
    entries = @pack.product_entries.where('amount > amount_sold').order(created_at: :asc)
    @product_entries = entries.map { |entry| {
      ostatok: entry.amount - entry.amount_sold,
      buy_price: "#{entry.buy_price} #{entry.paid_in_usd ? '$' : 'uzs'}"
    } }
    render json: @product_entries
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_pack
      @pack = Pack.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def pack_params
      params.require(:pack).permit(
        :name, :code, :barcode, :delivery_id, :buy_price, :sell_price, :price_in_usd, :initial_remaining,
        :product_category_id, :image, :unit,
        product_size_colors_attributes: [:size, :color_id, :amount]
      )
    end
end
