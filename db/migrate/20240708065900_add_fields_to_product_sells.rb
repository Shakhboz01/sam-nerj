class AddFieldsToProductSells < ActiveRecord::Migration[7.0]
  def change
    add_column :product_sells, :width, :decimal, precision: 10, scale: 2
    add_column :product_sells, :height, :decimal, precision: 10, scale: 2
    add_column :product_sells, :number_of_sizes, :decimal, precision: 10, scale: 2
  end
end
