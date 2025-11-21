class CreateAdminNotes < ActiveRecord::Migration[7.2]
  def change
    create_table :admin_notes do |t|
      t.text :note, null: false
      t.string :related_type, null: false
      t.bigint :related_id, null: false
      t.bigint :author_id, null: false

      t.timestamps
    end
    
    add_index :admin_notes, :author_id
    add_index :admin_notes, [:related_type, :related_id]
    add_foreign_key :admin_notes, :users, column: :author_id
  end
end
