# frozen_string_literal: true

module Catalog
  class ProductSerializer
    def initialize(product, options = {})
      @product = product
      @options = options
    end

    def as_json
      {
        type: 'product',
        id: @product.id.to_s,
        attributes: {
          title: @product.title,
          slug: @product.slug,
          description: @product.description,
          sku: @product.sku,
          price: {
            cents: @product.price_cents,
            currency: @product.currency,
            formatted: format_money(@product.price_cents, @product.currency)
          },
          base_price_cents: @product.base_price_cents,
          active: @product.active,
          in_stock: @product.in_stock?,
          total_stock: @product.total_stock,
          images: @product.images.attached? ? @product.images.map { |image| Rails.application.routes.url_helpers.url_for(image) } : [],
          created_at: @product.created_at,
          updated_at: @product.updated_at
        },
        relationships: relationships,
        links: {
          self: "/api/products/#{@product.slug}",
          variants: "/api/products/#{@product.slug}/variants"
        }
      }
    end

    def self.collection(products, options = {})
      {
        data: products.map { |product| new(product, options).as_json },
        meta: {
          total: products.size,
          cached_at: Time.current
        }
      }
    end

    private

    def relationships
      rels = {}

      if @product.category_id.present?
        rels[:category] = {
          data: { type: 'category', id: @product.category_id.to_s },
          links: { related: "/api/categories/#{@product.category_id}" }
        }
      end

      if @options[:include_variants]
        rels[:variants] = {
          data: @product.variants.map { |v| { type: 'variant', id: v.id.to_s } },
          meta: { count: @product.variants.count }
        }
      else
        rels[:variants] = {
          meta: { count: @product.variants.count },
          links: { related: "/api/products/#{@product.id}/variants" }
        }
      end

      rels
    end

    def format_money(cents, currency)
      "$#{sprintf('%.2f', cents / 100.0)}"
    end
  end
end
