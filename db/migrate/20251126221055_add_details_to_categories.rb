class AddDetailsToCategories < ActiveRecord::Migration[7.2]
  def change
    add_column :categories, :description, :text
    add_column :categories, :position, :integer, default: 0
    add_column :categories, :active, :boolean, default: true
    add_column :categories, :image_url, :string
    add_column :categories, :meta_title, :string
    add_column :categories, :meta_description, :text
    add_column :categories, :meta_keywords, :string
  end
end
