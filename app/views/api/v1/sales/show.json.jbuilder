json.success true
json.id @sale.id
json.created_at @sale.created_at.to_time.to_i
json.buyer_name translit(@sale.buyer.name&.capitalize)
json.registrator translit(@sale.user.name&.capitalize)
json.comment translit(@sale&.comment)
json.total_price @sale.total_price
json.product_sells do
  json.partial! collection: @product_sells, partial: 'api/v1/sales/product_sell', as: :product_sell
end
