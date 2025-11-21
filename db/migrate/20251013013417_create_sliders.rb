class CreateSliders < ActiveRecord::Migration[7.2]
  def change
    create_table :sliders do |t|
      t.string :title, null: false
      t.text :subtitle
      t.string :button_text
      t.string :button_link
      t.string :image_url
      t.integer :display_order, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :sliders, :display_order
    add_index :sliders, :active
  end
end
