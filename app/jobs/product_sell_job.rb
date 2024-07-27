# app/jobs/product_sell_job.rb
class ProductSellJob < ApplicationJob
  queue_as :default

  def perform(product_sell_id, action)
    product_sell = ProductSell.find(product_sell_id)
    return if product_sell.sale.buyer.is_worker

    send(action.to_sym, product_sell)
  end

  private

  def perform_sell(product_sell)
    pack = product_sell.pack
    sell_amount = product_sell.amount

    ActiveRecord::Base.transaction do
      total_buy_price_usd = 0
      total_sell_price = 0
      total_profit = 0
      usd_to_uzs_rate = CurrencyRate.last.rate

      product_entries = ProductEntry.where(pack_id: pack.id).order(created_at: :asc)
      remaining_amount = sell_amount

      product_entries.each do |entry|
        break if remaining_amount <= 0

        available_amount = entry.amount - entry.amount_sold
        amount_to_sell = [available_amount, remaining_amount].min

        buy_price_usd = entry.paid_in_usd ? entry.buy_price : entry.buy_price / usd_to_uzs_rate
        sell_price_usd = product_sell.price_in_usd ? product_sell.sell_price : product_sell.sell_price / usd_to_uzs_rate.to_f

        total_buy_price_usd += buy_price_usd * amount_to_sell
        total_sell_price += sell_price_usd * amount_to_sell
        total_profit += (sell_price_usd - buy_price_usd) * amount_to_sell

        entry.update!(amount_sold: entry.amount_sold + amount_to_sell)
        remaining_amount -= amount_to_sell
      end

      if remaining_amount > 0
        last_entry = product_entries.last
        buy_price_usd = last_entry.paid_in_usd ? last_entry.buy_price : last_entry.buy_price / usd_to_uzs_rate
        sell_price_usd = product_sell.price_in_usd ? product_sell.sell_price : product_sell.sell_price / usd_to_uzs_rate

        total_buy_price_usd += buy_price_usd * remaining_amount
        total_sell_price += sell_price_usd * remaining_amount
        total_profit += (sell_price_usd - buy_price_usd) * remaining_amount

        last_entry.update!(amount_sold: last_entry.amount_sold + remaining_amount)
      end

      unless product_sell.price_in_usd
        total_buy_price_usd *= usd_to_uzs_rate
        total_sell_price *= usd_to_uzs_rate
        total_profit *= usd_to_uzs_rate
      end

      product_sell.update!(
        buy_price: total_buy_price_usd / sell_amount,
        sell_price: total_sell_price / sell_amount,
        total_profit: total_profit
      )

    end
  rescue => e
    # Handle exceptions, possibly logging the error or notifying
    puts "Error: #{e.message}"
  end
end
