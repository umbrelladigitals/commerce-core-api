class CreateReviews < ActiveRecord::Migration[7.2]
  def change
    create_table :reviews do |t|
      t.references :product, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true # Optional for guest reviews
      t.string :guest_email
      t.integer :rating, null: false
      t.text :comment
      t.boolean :approved, default: false, null: false
      t.string :reviewer_ip # For spam control

      t.timestamps
    end
    
    # Indexes for performance and spam control
    add_index :reviews, [:product_id, :approved]
    add_index :reviews, [:user_id, :created_at]
    add_index :reviews, [:reviewer_ip, :created_at]
  end
end
