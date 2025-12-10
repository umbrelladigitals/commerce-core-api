# frozen_string_literal: true

# Kargo gönderimi modeli
# Siparişlerin kargo takip bilgilerini tutar
class Shipment < ApplicationRecord
  # İlişkiler
  belongs_to :order, class_name: 'Orders::Order'
  has_many :admin_notes, as: :related, dependent: :destroy
  
  # Kargo durumları
  # preparing: Hazırlanıyor
  # in_transit: Kargoda
  # out_for_delivery: Dağıtımda
  # delivered: Teslim edildi
  # failed: Teslimat başarısız
  # returned: İade edildi
  enum :status, { 
    preparing: 0, 
    in_transit: 1, 
    out_for_delivery: 2, 
    delivered: 3, 
    failed: 4, 
    returned: 5 
  }
  
  # Kargo firmaları
  CARRIERS = {
    ptt: 'PTT Kargo',
    aras: 'Aras Kargo',
    yurtici: 'Yurtiçi Kargo',
    mng: 'MNG Kargo',
    ups: 'UPS',
    dhl: 'DHL'
  }.freeze
  
  # Validasyonlar
  validates :order_id, presence: true, uniqueness: true
  validates :tracking_number, presence: true, uniqueness: true
  validates :carrier, presence: true, inclusion: { in: CARRIERS.keys.map(&:to_s) }
  validates :status, presence: true
  validate :delivered_at_after_shipped_at
  
  # Scope'lar
  scope :recent, -> { order(created_at: :desc) }
  scope :active, -> { where.not(status: [:delivered, :returned]) }
  scope :by_carrier, ->(carrier) { where(carrier: carrier) }
  scope :by_status, ->(status) { where(status: status) }
  
  # Callback'ler
  before_validation :set_shipped_at, if: :status_changed_to_transit?
  before_validation :set_delivered_at, if: :status_changed_to_delivered?
  after_update :update_order_status, if: :saved_change_to_status?
  after_create :notify_customer
  
  # Kargo firması görünen adı
  def carrier_name
    CARRIERS[carrier.to_sym] || carrier
  end
  
  # Takip URL'i (mock)
  def tracking_url
    case carrier.to_sym
    when :ptt
      "https://gonderitakip.ptt.gov.tr/Track/Verify?q=#{tracking_number}"
    when :aras
      "https://kargotakip.araskargo.com.tr/?code=#{tracking_number}"
    when :yurtici
      "https://www.yurticikargo.com/tr/online-servisler/gonderi-sorgula?code=#{tracking_number}"
    when :mng
      "https://www.mngkargo.com.tr/tr/kargo-takip?code=#{tracking_number}"
    when :ups
      "https://www.ups.com/track?tracknum=#{tracking_number}"
    when :dhl
      "https://www.dhl.com/en/express/tracking.html?AWB=#{tracking_number}"
    else
      "#"
    end
  end
  
  # Teslim edildi mi?
  def delivered?
    status == 'delivered' && delivered_at.present?
  end
  
  # Gecikme var mı?
  def delayed?
    return false unless estimated_delivery.present?
    return false if delivered?
    
    Date.today > estimated_delivery
  end
  
  # Tahmini gün sayısı
  def estimated_days
    return nil unless estimated_delivery.present?
    (estimated_delivery - Date.today).to_i
  end
  
  private
  
  def status_changed_to_transit?
    status_changed? && in_transit?
  end
  
  def status_changed_to_delivered?
    status_changed? && delivered?
  end
  
  def set_shipped_at
    self.shipped_at ||= Time.current
  end
  
  def set_delivered_at
    self.delivered_at ||= Time.current
  end
  
  def delivered_at_after_shipped_at
    return unless shipped_at.present? && delivered_at.present?
    
    if delivered_at < shipped_at
      errors.add(:delivered_at, 'teslimat tarihi kargo çıkış tarihinden önce olamaz')
    end
  end
  
  def update_order_status
    return unless order
    
    case status.to_sym
    when :delivered
      # Sipariş teslim edildi olarak işaretle
      order.update(status: :shipped) unless order.shipped?
    when :returned
      # İade durumunda siparişi iptal et
      order.update(status: :cancelled) if order.paid?
    end
  end
  
  def notify_customer
    # TODO: Email/SMS bildirimi
    # ShipmentNotificationJob.perform_later(id)
    Rails.logger.info "Shipment created for Order ##{order_id}: #{tracking_number}"
  end
end
