class CreateCategories < ActiveRecord::Migration[7.2]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :parent_id

      t.timestamps
    end

    add_index :categories, :slug, unique: true
    add_index :categories, :parent_id
  end
end
