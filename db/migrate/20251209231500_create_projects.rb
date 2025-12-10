class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string :name
      t.text :description
      t.integer :status
      t.references :user, null: false, foreign_key: true
      t.datetime :start_date
      t.datetime :due_date

      t.timestamps
    end
  end
end
