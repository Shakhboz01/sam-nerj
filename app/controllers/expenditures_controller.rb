class ExpendituresController < ApplicationController
  before_action :set_expenditure, only: %i[ show edit update destroy ]
  include Pundit::Authorization

  # GET /expenditures or /expenditures.json
  def index
    @q = Expenditure.ransack(params[:q])
    @expenditures = @q.result.order(id: :desc)
    @expenditures_data = @expenditures
    @expenditures = @expenditures.page(params[:page]).per(70)
    respond_to do |format|
      format.html
      format.xlsx
    end
  end

  # GET /expenditures/1 or /expenditures/1.json
  def show
    unless @expenditure.sale_ids.nil?
      ids = @expenditure.sale_ids.gsub(/\s+/, '').split(',')
      @sales = Sale.where(id: ids)
    end
  end

  # GET /expenditures/new
  def new
    @expenditure_types = Expenditure.expenditure_types.reject { |key, v| v == 1 }.keys
    @expenditure = Expenditure.new(
      combination_of_local_product_id: params[:combination_of_local_product_id],
      delivery_from_counterparty_id: params[:delivery_from_counterparty_id],
      expenditure_type: params[:expenditure_type],
    )
  end

  # GET /expenditures/1/edit
  def edit
  end

  # POST /expenditures or /expenditures.json
  def create
    @expenditure = Expenditure.new(expenditure_params)
    @expenditure.user_id = current_user.id
    respond_to do |format|
      if @expenditure.save
        if @expenditure.combination_of_local_product_id.present?
          format.html { redirect_to combination_of_local_product_path(@expenditure.combination_of_local_product), notice: "Expenditure was successfully created." }
        end

        if @expenditure.delivery_from_counterparty_id.present?
          format.html { redirect_to delivery_from_counterparty_path(@expenditure.delivery_from_counterparty), notice: "Expenditure was successfully created." }
        end

        format.html { redirect_to expenditures_url, notice: "Expenditure was successfully created." }
        format.json { render :show, status: :created, location: @expenditure }
      else
        Rails.logger.warn "ERROR OCCURED #{@expenditure.errors.messages}"
        format.html { render :new, expenditure_type: @expenditure_type, status: :unprocessable_entity }
        format.json { render json: @expenditure.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /expenditures/1 or /expenditures/1.json
  def update
    respond_to do |format|
      if @expenditure.update(expenditure_params)
        format.html { redirect_to expenditures_url, notice: "Expenditure was successfully updated." }
        format.json { render :show, status: :ok, location: @expenditure }
      else
        format.html { render :edit, expenditure_type: @expenditure_type, status: :unprocessable_entity }
        format.json { render json: @expenditure.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /expenditures/1 or /expenditures/1.json
  def destroy
    authorize Expenditure, :manage?

    respond_to do |format|
      if @expenditure.destroy
        format.html { redirect_to request.referrer, notice: "Expenditure was successfully destroyed." }
        format.json { head :no_content }
      else
        format.html { redirect_to request.referrer, notice: "Cannot be deleted" }
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_expenditure
    @expenditure = Expenditure.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def expenditure_params
    params.require(:expenditure).permit(:combination_of_local_product_id, :sale_ids, :price_in_usd, :comment, :image, :delivery_from_counterparty_id, :price, :price_in_usd, :price_in_uzs, :payment_type, :total_paid, :expenditure_type)
  end
end
