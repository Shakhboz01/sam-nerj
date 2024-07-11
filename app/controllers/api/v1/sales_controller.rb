module Api
  module V1
    class SalesController < Api1Controller
      def show
        @sale = Sale.find(params[:id])
        @product_sells = @sale.product_sells
      end
    end
  end
end
