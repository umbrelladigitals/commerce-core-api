# frozen_string_literal: true

module Catalog
  class ProductOption < ApplicationRecord
    # ============================================================================
    # Associations
    # ============================================================================
    belongs_to :product
    has_many :product_option_values, -> { order(position: :asc) },
             class_name: 'Catalog::ProductOptionValue',
             foreign_key: :product_option_id,
             dependent: :destroy

    # ============================================================================
    # Nested Attributes
    # ============================================================================
    accepts_nested_attributes_for :product_option_values, allow_destroy: true

    # ============================================================================
    # Validations
    # ============================================================================
    validates :name, presence: true, uniqueness: { scope: :product_id }
    validates :option_type, presence: true, inclusion: { 
      in: %w[select radio checkbox color],
      message: "%{value} is not a valid option type"
    }
    validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    # ============================================================================
    # Callbacks
    # ============================================================================
    before_validation :set_position, on: :create

    # ============================================================================
    # Scopes
    # ============================================================================
    scope :required, -> { where(required: true) }
    scope :optional, -> { where(required: false) }
    scope :by_position, -> { order(position: :asc) }

    # ============================================================================
    # Class Methods
    # ============================================================================
    def self.option_types
      %w[select radio checkbox color]
    end

    # ============================================================================
    # Instance Methods
    # ============================================================================
    
    # Opsiyonun açıklayıcı başlığı
    # @return [String]
    def display_name
      required? ? "#{name} *" : name
    end

    # Opsiyonun en düşük fiyatlı değeri
    # @return [ProductOptionValue, nil]
    def cheapest_value
      product_option_values.order(price_cents: :asc).first
    end

    # Opsiyonun en yüksek fiyatlı değeri
    # @return [ProductOptionValue, nil]
    def most_expensive_value
      product_option_values.order(price_cents: :desc).first
    end

    # Fiyat aralığı (min-max)
    # @return [Hash]
    def price_range
      values = product_option_values.pluck(:price_cents)
      return { min: 0, max: 0 } if values.empty?

      {
        min: values.min,
        max: values.max,
        min_formatted: Money.new(values.min, 'USD').format,
        max_formatted: Money.new(values.max, 'USD').format
      }
    end

    # Opsiyon değerlerinin sayısı
    # @return [Integer]
    def values_count
      product_option_values.count
    end

    # JSON API için serialize
    # @return [Hash]
    def as_json_api
      {
        id: id,
        name: name,
        display_name: display_name,
        option_type: option_type,
        required: required,
        position: position,
        values_count: values_count,
        price_range: price_range,
        values: product_option_values.map(&:as_json_api)
      }
    end

    private

    def set_position
      return if position.present?
      
      max_position = product.product_options.maximum(:position) || -1
      self.position = max_position + 1
    end
  end
end
