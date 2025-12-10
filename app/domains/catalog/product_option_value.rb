# frozen_string_literal: true

module Catalog
  class ProductOptionValue < ApplicationRecord
    # ============================================================================
    # Money-Rails
    # ============================================================================
    monetize :price_cents, as: :price

    # ============================================================================
    # Associations
    # ============================================================================
    belongs_to :product_option

    # ============================================================================
    # Validations
    # ============================================================================
    validates :name, presence: true, uniqueness: { scope: :product_option_id }
    validates :price_cents, presence: true, numericality: { 
      only_integer: true
    }
    validates :price_mode, presence: true, inclusion: { 
      in: %w[flat per_unit],
      message: "%{value} is not a valid price mode"
    }
    validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validate :meta_must_be_hash

    # ============================================================================
    # Callbacks
    # ============================================================================
    before_validation :set_defaults, on: :create

    # ============================================================================
    # Scopes
    # ============================================================================
    scope :flat_price, -> { where(price_mode: 'flat') }
    scope :per_unit_price, -> { where(price_mode: 'per_unit') }
    scope :free, -> { where(price_cents: 0) }
    scope :paid, -> { where('price_cents > 0') }
    scope :by_position, -> { order(position: :asc) }

    # ============================================================================
    # Class Methods
    # ============================================================================
    def self.price_modes
      %w[flat per_unit]
    end

    # ============================================================================
    # Instance Methods
    # ============================================================================
    
    # Fiyat modu flat mi?
    # @return [Boolean]
    def flat_price?
      price_mode == 'flat'
    end

    # Fiyat modu per_unit mi?
    # @return [Boolean]
    def per_unit_price?
      price_mode == 'per_unit'
    end

    # Ücretsiz mi?
    # @return [Boolean]
    def free?
      price_cents.zero?
    end

    # Belirli bir miktar için toplam fiyat hesapla
    # @param quantity [Integer] miktar (default: 1)
    # @return [Integer] toplam fiyat (cents)
    def calculate_price(quantity = 1)
      case price_mode
      when 'flat'
        # Flat: Miktar ne olursa olsun sabit fiyat
        price_cents
      when 'per_unit'
        # Per Unit: Her birim için fiyat
        price_cents * quantity
      else
        0
      end
    end

    # Fiyat açıklaması (formatlanmış)
    # @return [String]
    def price_description
      if free?
        "Free"
      elsif flat_price?
        "+#{price.format} (one-time)"
      else
        "+#{price.format} per unit"
      end
    end

    # Görünen ad (fiyat ile birlikte)
    # @return [String]
    def display_name
      return name if free?
      "#{name} (#{price_description})"
    end

    # Meta verisinden belirli bir değer getir
    # @param key [String, Symbol]
    # @return [Object, nil]
    def meta_value(key)
      meta&.dig(key.to_s)
    end

    # Meta verisine değer ekle veya güncelle
    # @param key [String, Symbol]
    # @param value [Object]
    def set_meta(key, value)
      self.meta ||= {}
      self.meta[key.to_s] = value
    end

    # Renk opsiyonu için hex kodu
    # @return [String, nil]
    def color_hex
      meta_value('color_hex')
    end

    # Renk opsiyonu için hex kodu ata
    # @param hex [String]
    def color_hex=(hex)
      set_meta('color_hex', hex)
    end

    # Görsel URL (renk swatch, pattern vb için)
    # @return [String, nil]
    def image_url
      meta_value('image_url')
    end

    # Stok kodu (variant ile ilişki için)
    # @return [String, nil]
    def sku
      meta_value('sku')
    end

    # Açıklama metni
    # @return [String, nil]
    def description
      meta_value('description')
    end

    # JSON API için serialize
    # @return [Hash]
    def as_json_api
      {
        id: id,
        name: name,
        display_name: display_name,
        price_cents: price_cents,
        price_formatted: price.format,
        price_mode: price_mode,
        price_description: price_description,
        position: position,
        free: free?,
        meta: meta
      }
    end

    private

    def set_defaults
      self.meta ||= {}
      
      if position.blank?
        max_position = product_option.product_option_values.maximum(:position) || -1
        self.position = max_position + 1
      end
    end

    def meta_must_be_hash
      return if meta.nil? || meta.is_a?(Hash)
      
      errors.add(:meta, "must be a hash")
    end
  end
end
