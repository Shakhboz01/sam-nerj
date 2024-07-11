module DataPopulation
  class PopulateProducts < ActiveInteraction::Base
    def execute
      products_data = JSON.parse(File.read('app/assets/javascripts/products.json'))
      product_category = ProductCategory.find_or_create_by(name: 'Смешанные')
      products_data.each do |product_data|
        create_products(product_data, ProductCategory.last&.id)
      end
    end

    private

    def create_products(data, category_id)
      name = data['pack']
      initial_remaining = 0
      price_in_usd = false
      buy_price = 10000
      sell_price = data['price'].nil? ? 10000 : data['price'].to_f * 100
      unit = data['unit'].nil? ? 4 : data['unit']

      if data['price'].nil?
        ProductCategory.create(name: data['pack'])
        return
      end

      pr = Pack.create(
        name: name,
        code: '',
        product_category_id: category_id,
        price_in_usd: price_in_usd,
        buy_price: buy_price,
        sell_price: sell_price,
        initial_remaining: initial_remaining,
        unit: unit
      )
      puts pr.errors.messages
    end
  end
end
