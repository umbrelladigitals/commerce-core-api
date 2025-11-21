# frozen_string_literal: true

module Catalog
  class VariantSerializer
    def initialize(variant, options = {})
      @variant = variant
      @options = options
    end

    def as_json
      {
        type: 'variant',
        id: @variant.id.to_s,
        attributes: {
          sku: @variant.sku,
          options: @variant.options,
          price: {
            cents: @variant.price_cents,
            currency: @variant.currency,
            formatted: format_money(@variant.price_cents, @variant.currency)
          },
          stock: @variant.stock,
          in_stock: @variant.in_stock?,
          display_name: @variant.display_name,
          created_at: @variant.created_at,
          updated_at: @variant.updated_at
        },
        relationships: {
          product: {
            data: { type: 'product', id: @variant.product_id.to_s },
            links: { related: "/api/products/#{@variant.product_id}" }
          }
        },
        links: {
          self: "/api/products/#{@variant.product_id}/variants/#{@variant.id}"
        }
      }
    end

    def self.collection(variants, options = {})
      {
        data: variants.map { |variant| new(variant, options).as_json },
        meta: {
          total: variants.size,
          total_stock: variants.sum(&:stock)
        }
      }
    end

    private

    def format_money(cents, currency)
      "$#{sprintf('%.2f', cents / 100.0)}"
    end
  end
end
