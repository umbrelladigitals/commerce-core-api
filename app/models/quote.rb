# frozen_string_literal: true

# Teklif/Proforma modeli
# Yöneticiler müşteri/bayi adına teklif oluşturabilir
class Quote < ApplicationRecord
  # İlişkiler
  belongs_to :user # Teklif verilen müşteri/bayi
  belongs_to :created_by, class_name: 'User', foreign_key: 'created_by_id' # Teklifi oluşturan admin
  has_many :quote_lines, dependent: :destroy
  has_many :products, through: :quote_lines
  has_many :admin_notes, as: :related, dependent: :destroy
  
  # Money-Rails entegrasyonu
  monetize :subtotal_cents, as: :subtotal
  monetize :tax_cents, as: :tax
  monetize :shipping_cents, as: :shipping
  monetize :total_cents, as: :total
  
  # Teklif durumları
  # draft: Taslak
  # sent: Gönderildi
  # accepted: Kabul edildi (siparişe dönüştü)
  # rejected: Reddedildi
  # expired: Süresi doldu
  enum status: { draft: 0, sent: 1, accepted: 2, rejected: 3, expired: 4 }
  
  # Validasyonlar
  validates :quote_number, presence: true, uniqueness: true
  validates :user_id, presence: true
  validates :created_by_id, presence: true
  validates :valid_until, presence: true
  validates :status, presence: true
  validates :total_cents, numericality: { greater_than_or_equal_to: 0 }
  validate :valid_until_is_future, on: :create
  
  # Scope'lar
  scope :recent, -> { order(created_at: :desc) }
  scope :active, -> { where(status: [:draft, :sent]).where('valid_until >= ?', Date.today) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :created_by, ->(admin_id) { where(created_by_id: admin_id) }
  scope :expiring_soon, -> { where(status: :sent).where('valid_until <= ?', 7.days.from_now) }
  
  # Callback'ler
  before_validation :generate_quote_number, on: :create
  before_validation :set_default_valid_until, on: :create
  after_create :calculate_totals
  
  # Teklif numarası oluştur (örn: QUO-20231010-001)
  def quote_number_display
    quote_number
  end
  
  # Geçerlilik durumu
  def expired?
    valid_until < Date.today
  end
  
  def active?
    (draft? || sent?) && !expired?
  end
  
  # Siparişe dönüştür
  def convert_to_order!
    return false unless sent? && !expired?
    
    ActiveRecord::Base.transaction do
      order = Orders::Order.create!(
        user: user,
        status: :cart,
        currency: currency
      )
      
      quote_lines.each do |line|
        order.order_lines.create!(
          product_id: line.product_id,
          variant_id: line.variant_id,
          quantity: line.quantity,
          note: "Teklif ##{quote_number} - #{line.note}".strip
        )
      end
      
      # Fiyatları hesapla
      Orders::OrderPriceCalculator.new(order).calculate!
      
      # Teklifi kabul edildi olarak işaretle
      update!(status: :accepted)
      
      # Not ekle
      admin_notes.create!(
        note: "Teklif siparişe dönüştürüldü: Order ##{order.id}",
        author: created_by
      )
      
      order
    end
  rescue StandardError => e
    Rails.logger.error "Teklif siparişe dönüştürülemedi: #{e.message}"
    false
  end
  
  # Toplam ürün sayısı
  def total_items
    quote_lines.sum(:quantity)
  end
  
  private
  
  def generate_quote_number
    return if quote_number.present?
    
    # QUO-20231010-001 formatında
    date_part = Date.today.strftime('%Y%m%d')
    last_quote = Quote.where('quote_number LIKE ?', "QUO-#{date_part}-%").order(quote_number: :desc).first
    
    if last_quote
      last_number = last_quote.quote_number.split('-').last.to_i
      new_number = last_number + 1
    else
      new_number = 1
    end
    
    self.quote_number = "QUO-#{date_part}-#{new_number.to_s.rjust(3, '0')}"
  end
  
  def set_default_valid_until
    self.valid_until ||= 30.days.from_now.to_date
  end
  
  def valid_until_is_future
    if valid_until.present? && valid_until < Date.today
      errors.add(:valid_until, 'geçmiş tarihte olamaz')
    end
  end
  
  def calculate_totals
    return unless quote_lines.any?
    
    subtotal = quote_lines.sum(&:total_cents)
    shipping = calculate_shipping(subtotal)
    tax = calculate_tax(subtotal, shipping)
    
    update_columns(
      subtotal_cents: subtotal,
      shipping_cents: shipping,
      tax_cents: tax,
      total_cents: subtotal + shipping + tax
    )
  end
  
  def calculate_shipping(subtotal)
    # Bayi için $100 üzeri, müşteri için $200 üzeri ücretsiz
    threshold = user.dealer? ? 10_000 : 20_000 # cents
    subtotal >= threshold ? 0 : 3000 # $30
  end
  
  def calculate_tax(subtotal, shipping)
    # %18 KDV
    ((subtotal + shipping) * 0.18).to_i
  end
end
