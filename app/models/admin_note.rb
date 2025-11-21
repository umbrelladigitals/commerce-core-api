# frozen_string_literal: true

# Admin notları
# Yöneticiler sipariş, bayi, müşteri vb. ile ilgili notlar ekleyebilir
class AdminNote < ApplicationRecord
  # İlişkiler
  belongs_to :author, class_name: 'User', foreign_key: 'author_id'
  belongs_to :related, polymorphic: true
  
  # Validasyonlar
  validates :note, presence: true, length: { minimum: 3, maximum: 5000 }
  validates :related_type, presence: true
  validates :related_id, presence: true
  validates :author_id, presence: true
  
  # Scope'lar
  scope :recent, -> { order(created_at: :desc) }
  scope :for_orders, -> { where(related_type: 'Orders::Order') }
  scope :for_users, -> { where(related_type: 'User') }
  scope :for_quotes, -> { where(related_type: 'Quote') }
  scope :by_author, ->(author_id) { where(author_id: author_id) }
  
  # Callback'ler
  before_validation :normalize_related_type
  
  private
  
  def normalize_related_type
    # "Order" -> "Orders::Order" gibi namespace düzeltmeleri
    case related_type
    when 'Order'
      self.related_type = 'Orders::Order'
    when 'DealerBalance'
      self.related_type = 'B2b::DealerBalance'
    end
  end
end
