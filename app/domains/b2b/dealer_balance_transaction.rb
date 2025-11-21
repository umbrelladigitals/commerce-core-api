# frozen_string_literal: true

module B2b
  # Dealer bakiye işlem geçmişi
  # Her bakiye değişikliği için detaylı kayıt tutar
  #
  # Transaction Types:
  #   - credit: Bakiyeye para ekleme
  #   - debit: Bakiyeden para çekme
  #   - topup: Manuel yükleme
  #   - order_payment: Sipariş ödemesi
  #
  # Örnek:
  #   balance = B2b::DealerBalance.first
  #   transaction = balance.transactions.create!(
  #     transaction_type: :topup,
  #     amount_cents: 50000,
  #     note: "Kredi kartı ile yükleme"
  #   )
  class DealerBalanceTransaction < ApplicationRecord
    self.table_name = 'dealer_balance_transactions'
    
    # İlişkiler
    belongs_to :dealer_balance, class_name: 'B2b::DealerBalance'
    belongs_to :order, class_name: 'Orders::Order', optional: true
    
    # Para birimi entegrasyonu
    monetize :amount_cents, as: :amount
    
    # İşlem tipleri
    enum transaction_type: {
      credit: 'credit',           # Genel kredi ekleme
      debit: 'debit',             # Genel borç düşme
      topup: 'topup',             # Manuel bakiye yükleme
      order_payment: 'order_payment', # Sipariş ödemesi
      refund: 'refund',           # İade
      adjustment: 'adjustment'     # Manuel düzeltme (admin)
    }
    
    # Validasyonlar
    validates :dealer_balance, presence: true
    validates :transaction_type, presence: true
    validates :amount_cents, presence: true, numericality: true
    
    # Scope'lar
    scope :recent, -> { order(created_at: :desc) }
    scope :credits, -> { where(transaction_type: %w[credit topup refund]) }
    scope :debits, -> { where(transaction_type: %w[debit order_payment]) }
    scope :for_dealer, ->(dealer_id) {
      joins(:dealer_balance).where(dealer_balances: { dealer_id: dealer_id })
    }
    
    # Callback'ler
    before_validation :set_defaults, on: :create
    
    # İşlem tipini anlamlı isimle döndür
    def type_label
      {
        'credit' => 'Kredi Ekleme',
        'debit' => 'Borç Düşme',
        'topup' => 'Bakiye Yükleme',
        'order_payment' => 'Sipariş Ödemesi',
        'refund' => 'İade',
        'adjustment' => 'Düzeltme'
      }[transaction_type] || transaction_type.humanize
    end
    
    # İşlem pozitif mi negatif mi?
    def positive?
      %w[credit topup refund].include?(transaction_type)
    end
    
    def negative?
      !positive?
    end
    
    # İşlemden sonra bakiye
    def balance_after
      dealer_balance.balance
    end
    
    private
    
    def set_defaults
      self.amount_cents = 0 if amount_cents.nil?
    end
  end
end
