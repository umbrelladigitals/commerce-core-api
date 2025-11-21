# frozen_string_literal: true

module Catalog
  class Variant < ApplicationRecord
    self.table_name = 'variants'

    # Money management
    monetize :price_cents, as: :price

    # Associations
    belongs_to :product, class_name: 'Catalog::Product'

    # Validations
    validates :sku, presence: true, uniqueness: true
    validates :price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :stock, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validate :options_must_be_hash

    # Callbacks
    before_validation :generate_sku, if: -> { sku.blank? }

    # Scopes
    scope :in_stock, -> { where('stock > 0') }
    scope :out_of_stock, -> { where(stock: 0) }
    scope :by_option, ->(key, value) { where("options->>'#{key}' = ?", value.to_s) }

    # Instance methods
    def in_stock?
      stock > 0
    end

    def out_of_stock?
      stock.zero?
    end

    def option(key)
      options[key.to_s]
    end

    def set_option(key, value)
      self.options = options.merge(key.to_s => value)
    end

    def display_name
      return product.title if options.blank?
      
      options_text = options.map { |k, v| "#{k}: #{v}" }.join(', ')
      "#{product.title} (#{options_text})"
    end

    private

    def generate_sku
      self.sku = "VAR-#{SecureRandom.hex(4).upcase}"
    end

    def options_must_be_hash
      return if options.is_a?(Hash)
      
      errors.add(:options, 'must be a valid JSON object')
    end
  end
end
