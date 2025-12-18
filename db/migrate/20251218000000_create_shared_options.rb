class CreateSharedOptions < ActiveRecord::Migration[8.1]
  def change
    create_table :shared_options do |t|
      t.string :name, null: false
      t.string :option_type, null: false, default: 'select'
      t.boolean :required, null: false, default: false
      t.integer :position, default: 0

      t.timestamps
    end

    create_table :shared_option_values do |t|
      t.references :shared_option, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :price_cents, null: false, default: 0
      t.string :price_mode, null: false, default: 'flat'
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :shared_options, :name, unique: true
    add_index :shared_option_values, [:shared_option_id, :name], unique: true
  end
end
