class AddSlugToProducts < ActiveRecord::Migration[7.2]
  def change
    add_column :products, :slug, :string
    add_index :products, :slug, unique: true
    
    # Generate slugs for existing products
    reversible do |dir|
      dir.up do
        # Will be handled by model callback
        execute <<-SQL
          UPDATE products 
          SET slug = LOWER(
            REGEXP_REPLACE(
              REGEXP_REPLACE(title, '[^a-zA-Z0-9\s-]', '', 'g'),
              '\s+', '-', 'g'
            )
          )
          WHERE slug IS NULL;
        SQL
      end
    end
  end
end
