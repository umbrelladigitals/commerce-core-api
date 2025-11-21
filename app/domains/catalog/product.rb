# frozen_string_literal: true

module Catalog
  class Product < ApplicationRecord
    self.table_name = 'products'
    
    # Concerns
    include Sluggable
    
    # Attachments
    has_many_attached :images
    
    # Money management
    monetize :price_cents, as: :price

    # Associations
    belongs_to :category, class_name: 'Catalog::Category', optional: true
    has_many :variants, class_name: 'Catalog::Variant', dependent: :destroy
    has_many :order_items, class_name: 'Orders::OrderItem', dependent: :restrict_with_error
    has_many :product_options, -> { order(position: :asc) }, 
             class_name: 'Catalog::ProductOption', 
             dependent: :destroy
    has_many :product_option_values, through: :product_options
    has_many :reviews, dependent: :destroy
    has_many :approved_reviews, -> { approved }, class_name: 'Review'
    
    # Alias for convenience
    alias_method :options, :product_options

    # Nested attributes
    accepts_nested_attributes_for :variants, allow_destroy: true
    accepts_nested_attributes_for :product_options, allow_destroy: true

    # Validations
    validates :title, presence: true
    validates :sku, presence: true, uniqueness: true
    validates :price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :active, inclusion: { in: [true, false] }

    # Callbacks
    before_validation :generate_sku, if: -> { sku.blank? }

    # Scopes
    scope :active, -> { where(active: true) }
    scope :inactive, -> { where(active: false) }
    scope :in_category, ->(category_id) { where(category_id: category_id) }
    scope :search, ->(query) { where('title ILIKE ? OR description ILIKE ?', "%#{query}%", "%#{query}%") }
    scope :with_stock, -> { joins(:variants).where('variants.stock > 0').distinct }

    # Cache key
    def self.cache_key_with_version
      "#{model_name.cache_key}/#{maximum(:updated_at)&.to_i || 0}"
    end

    # Instance methods
    def in_stock?
      variants.any? && variants.sum(:stock) > 0
    end

    def total_stock
      variants.sum(:stock)
    end

    def available_variants
      variants.where('stock > 0')
    end

    # Ürünün opsiyonları var mı?
    def has_options?
      product_options.any?
    end

    # Zorunlu opsiyonlar
    def required_options
      product_options.required
    end

    # Opsiyonel opsiyonlar
    def optional_options
      product_options.optional
    end

    # Tüm opsiyonları detaylı bilgi ile döndür
    def options_with_values
      product_options.includes(:product_option_values).map(&:as_json_api)
    end
    
    # Review methods
    def average_rating
      approved_reviews.average(:rating)&.round(2) || 0.0
    end
    
    def reviews_count
      approved_reviews.count
    end

    private

    def generate_sku
      self.sku = "PROD-#{SecureRandom.hex(4).upcase}"
    end
  end
end
