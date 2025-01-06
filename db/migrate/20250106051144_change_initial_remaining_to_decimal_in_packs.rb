class ChangeInitialRemainingToDecimalInPacks < ActiveRecord::Migration[7.0]
  def change
    change_column :packs, :initial_remaining, :decimal, precision: 17, scale: 2, default: 0.0
  end
end
