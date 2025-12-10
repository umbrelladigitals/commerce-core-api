class AddTagsToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :tags, :string, array: true, default: []
  end
end
