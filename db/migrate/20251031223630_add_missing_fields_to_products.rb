class AddMissingFieldsToProducts < ActiveRecord::Migration[7.2]
  def change
    add_column :products, :tax_rate, :decimal, precision: 5, scale: 4, default: 0.20
    add_column :products, :brand, :string
    add_column :products, :featured, :boolean, default: false
    add_column :products, :short_description, :text
    add_column :products, :sku_prefix, :string
    add_column :products, :base_price_cents, :integer, default: 0
    add_column :products, :cost_price_cents, :integer, default: 0
    add_column :products, :meta_title, :string
    add_column :products, :meta_description, :text
  end
end
