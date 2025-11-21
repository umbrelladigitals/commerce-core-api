# frozen_string_literal: true

module Orders
  class Order < ApplicationRecord
    self.table_name = 'orders'
    
    # İlişkiler
    belongs_to :user, optional: true # Guest checkout için optional
    belongs_to :created_by_marketer, class_name: 'User', optional: true
    has_many :order_lines, dependent: :destroy
    has_many :products, through: :order_lines
    has_many :status_logs, class_name: 'OrderStatusLog', dependent: :destroy
    has_many :admin_notes, as: :related, dependent: :destroy
    has_one :shipment, dependent: :destroy
    
    # Para birimleri için Money-Rails entegrasyonu
    monetize :total_cents, as: :total
    monetize :subtotal_cents, as: :subtotal
    monetize :tax_cents, as: :tax
    monetize :shipping_cents, as: :shipping
    monetize :discount_cents, as: :discount, allow_nil: true
    
    # Sipariş durumları
    # cart: Sepet aşamasında (henüz ödeme yapılmamış)
    # pending: Sipariş alındı, ödeme bekleniyor (havale/EFT için)
    # paid: Ödeme alındı, işleme hazır
    # shipped: Kargoya verildi
    # cancelled: İptal edildi
    enum status: { cart: 0, paid: 1, shipped: 2, cancelled: 3, pending: 4 }
    
    # Üretim durumları (Manufacturing için)
    # pending: Üretim bekliyor
    # in_production: Üretimde
    # ready: Hazır, sevkiyat bekliyor
    # shipped: Sevk edildi
    enum production_status: { pending: 'pending', in_production: 'in_production', ready: 'ready', shipped: 'shipped' }, _prefix: true
    
    # Validasyonlar
    validates :status, presence: true
    validates :total_cents, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
    validates :tax_cents, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
    
    # Scope'lar
    scope :active_carts, -> { where(status: :cart).where('updated_at > ?', 24.hours.ago) }
    scope :completed, -> { where(status: [:paid, :shipped]) }
    scope :pending_shipment, -> { where(status: :paid) }
    
    # Callback'ler
    after_initialize :set_default_status, if: :new_record?
    before_save :calculate_totals, if: :order_lines_changed?
    after_commit :enqueue_status_notification, if: :saved_change_to_status?
    
    # Sipariş numarası oluştur (örn: ORD-20231010-001)
    def order_number
      @order_number ||= "ORD-#{created_at.strftime('%Y%m%d')}-#{id.to_s.rjust(6, '0')}"
    end
    

    
    # Toplam ürün sayısı
    def total_items
      order_lines.sum(:quantity)
    end
    
    # Sipariş ödemesi yapılabilir mi?
    def payable?
      cart? && order_lines.any? && all_items_in_stock?
    end
    
    # Tüm ürünler stokta mı?
    def all_items_in_stock?
      order_lines.all? do |line|
        if line.variant_id.present?
          line.variant.stock >= line.quantity
        elsif line.product.variants.empty?
          # Variant olmayan ürünler için stok kontrolü yapma
          true
        else
          # Product variant'lı ama bu line'da variant seçilmemişse
          # Bu durumda product'ın toplam stoğuna bak
          line.product.total_stock >= line.quantity
        end
      end
    end
    
    # Siparişi ödenmiş olarak işaretle
    def mark_as_paid!
      update!(
        status: :paid, 
        paid_at: Time.current,
        payment_status: :completed
      )
    end
    
    # Siparişi ödeme bekliyor olarak işaretle (havale/EFT için)
    def mark_as_pending!
      update!(
        status: :pending,
        payment_status: :pending
      )
    end
    
    # Siparişi kargoya verilmiş olarak işaretle
    def mark_as_shipped!
      update!(status: :shipped, shipped_at: Time.current)
    end
    
    # Siparişi iptal et
    def cancel!
      return false unless cart? || paid?
      
      transaction do
        # Stokları geri ver
        restore_stock!
        update!(status: :cancelled, cancelled_at: Time.current)
      end
    end
    
    # Üretim durumunu değiştir ve logla
    def update_production_status!(new_status, changed_by_user)
      old_status = production_status
      
      transaction do
        update!(production_status: new_status)
        
        # Status değişikliğini logla
        status_logs.create!(
          user: changed_by_user,
          from_status: old_status,
          to_status: new_status,
          changed_at: Time.current
        )

        # Kargoya verildiyse bildirim gönder
        if new_status == 'shipped' && old_status != 'shipped'
          NotificationMailer.order_shipped(self).deliver_later
        end
      end
    end
    
    # Stokları geri yükle
    def restore_stock!
      order_lines.each do |line|
        if line.variant_id.present?
          line.variant.increment!(:stock, line.quantity)
        end
      end
    end
    
    private
    
    def set_default_status
      self.status ||= :cart
      self.total_cents ||= 0
      self.subtotal_cents ||= 0
      self.tax_cents ||= 0
      self.shipping_cents ||= 0
    end
    
    def order_lines_changed?
      order_lines.any?(&:changed?)
    end
    
    def calculate_totals
      # Bu method OrderPriceCalculator servis tarafından çağrılacak
      # Manuel hesaplama yapılmaması için boş bırakıldı
    end
    
    def enqueue_status_notification
      # Get previous and current status
      from_status, to_status = saved_change_to_status
      
      # Don't send notification for cart status
      return if to_status == 'cart'
      
      # Enqueue job to send notification
      OrderStatusChangedJob.perform_later(id, from_status, to_status)
    end
  end
end
