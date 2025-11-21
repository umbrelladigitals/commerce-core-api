# frozen_string_literal: true

namespace :products do
  desc "Generate proper slugs for existing products with Turkish character support"
  task generate_slugs: :environment do
    puts "Generating slugs for existing products..."

    Catalog::Product.find_each do |product|
      # Force regenerate slug with Turkish support
      product.slug = nil
      product.save(validate: false) # Skip validation first time
      product.save! # Then validate
      puts "Generated slug for '#{product.title}': #{product.slug}"
    end

    puts "Done! Total products: #{Catalog::Product.count}"
  end
end
