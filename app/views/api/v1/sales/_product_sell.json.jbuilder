json.id product_sell.id
json.amount product_sell.amount
json.sell_price product_sell.sell_price
json.total_price (product_sell.sell_price * product_sell.amount)
json.product_name product_sell.pack.name
# json.product_name translit(product_sell.pack.name)
