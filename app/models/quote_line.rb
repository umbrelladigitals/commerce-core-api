# frozen_string_literal: true

# Teklif satırı modeli
# Her teklif birden fazla ürün içerebilir
class QuoteLine < ApplicationRecord
  # İlişkiler
  belongs_to :quote
  belongs_to :product, class_name: 'Catalog::Product'
  belongs_to :variant, class_name: 'Catalog::Variant', optional: true
  
  # Money-Rails entegrasyonu
  monetize :unit_price_cents, as: :unit_price, allow_nil: false
  monetize :total_cents, as: :total, allow_nil: false
  
  # Validasyonlar
  validates :product_id, presence: true
  validates :product_title, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  # Callback'ler
  before_validation :set_product_details, on: :create
  before_validation :calculate_line_total
  after_save :update_quote_totals
  after_destroy :update_quote_totals
  
  # Satır toplamını hesapla
  def calculate_line_total
    self.total_cents = (unit_price_cents || 0) * (quantity || 1)
  end
  
  # Varyant görünen adı
  def variant_display_name
    return nil unless variant
    variant.display_name
  end
  
  private
  
  def set_product_details
    return unless product
    
    self.product_title ||= product.title
    
    if variant
      self.variant_name ||= variant.display_name
      self.unit_price_cents ||= variant.price_cents
    else
      self.unit_price_cents ||= product.price_cents
    end
  end
  
  def update_quote_totals
    return unless quote
    
    subtotal = quote.quote_lines.sum(&:total_cents)
    shipping = calculate_shipping(subtotal)
    tax = calculate_tax(subtotal, shipping)
    
    quote.update_columns(
      subtotal_cents: subtotal,
      shipping_cents: shipping,
      tax_cents: tax,
      total_cents: subtotal + shipping + tax
    )
  end
  
  def calculate_shipping(subtotal)
    threshold = quote.user.dealer? ? 10_000 : 20_000
    subtotal >= threshold ? 0 : 3000
  end
  
  def calculate_tax(subtotal, shipping)
    ((subtotal + shipping) * 0.18).to_i
  end
end
