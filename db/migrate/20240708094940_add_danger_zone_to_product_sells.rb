class AddDangerZoneToProductSells < ActiveRecord::Migration[7.0]
  def change
    add_column :product_sells, :danger_zone, :boolean, defaulr: false
  end
end
