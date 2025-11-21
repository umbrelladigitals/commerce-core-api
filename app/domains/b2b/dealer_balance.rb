# frozen_string_literal: true

module B2b
  # Dealer bakiye yönetimi
  # Her dealer'ın cari hesabı ve kredi limiti
  #
  # Örnek:
  #   dealer = User.find_by(role: :dealer)
  #   balance = B2b::DealerBalance.find_or_create_by!(dealer: dealer)
  #   balance.add_credit!(10000) # 100.00 TL ekle
  #   balance.deduct!(5000)      # 50.00 TL düş
  class DealerBalance < ApplicationRecord
    self.table_name = 'dealer_balances'
    
    # İlişkiler
    belongs_to :dealer, class_name: 'User', foreign_key: :dealer_id
    has_many :transactions, class_name: 'B2b::DealerBalanceTransaction', dependent: :destroy
    
    # Para birimi entegrasyonu
    monetize :balance_cents, as: :balance
    monetize :credit_limit_cents, as: :credit_limit
    
    # Validasyonlar
    validates :dealer, presence: true, uniqueness: true
    validates :balance_cents, presence: true, numericality: true
    validates :credit_limit_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validate :dealer_must_be_dealer_role
    
    # Callback'ler
    after_initialize :set_defaults, if: :new_record?
    before_save :update_last_transaction_at, if: :balance_cents_changed?
    
    # Scope'lar
    scope :with_positive_balance, -> { where('balance_cents > 0') }
    scope :with_negative_balance, -> { where('balance_cents < 0') }
    scope :over_credit_limit, -> { where('balance_cents < -credit_limit_cents') }
    
    # Bakiyeye para ekle (ödeme yapıldığında)
    # @param amount_cents [Integer] Eklenecek miktar (cents cinsinden)
    # @param note [String] İşlem notu (opsiyonel)
    # @return [Boolean] Başarılı olup olmadığı
    def add_credit!(amount_cents, note: nil)
      return false if amount_cents <= 0
      
      transaction do
        increment!(:balance_cents, amount_cents)
        log_transaction(:credit, amount_cents, note)
      end
      
      true
    end
    
    # Bakiyeden para düş (sipariş verildiğinde)
    # @param amount_cents [Integer] Düşülecek miktar (cents cinsinden)
    # @param note [String] İşlem notu (opsiyonel)
    # @param order_id [Integer] İlişkili sipariş ID (opsiyonel)
    # @return [Boolean] Başarılı olup olmadığı
    def deduct!(amount_cents, note: nil, order_id: nil)
      return false if amount_cents <= 0
      
      # Kredi limiti kontrolü
      new_balance = balance_cents - amount_cents
      if new_balance < -credit_limit_cents
        errors.add(:base, "Insufficient balance. Credit limit: #{credit_limit.format}")
        return false
      end
      
      transaction do
        decrement!(:balance_cents, amount_cents)
        log_transaction(:debit, amount_cents, note, order_id: order_id)
      end
      
      true
    end
    
    # Manuel bakiye yükleme (topup)
    # @param amount_cents [Integer] Yüklenecek miktar (cents cinsinden)
    # @param note [String] İşlem notu (opsiyonel)
    # @return [Boolean] Başarılı olup olmadığı
    def topup!(amount_cents, note: "Manuel bakiye yükleme")
      return false if amount_cents <= 0
      
      transaction do
        increment!(:balance_cents, amount_cents)
        log_transaction(:topup, amount_cents, note)
      end
      
      true
    end
    
    # Kullanılabilir bakiye (bakiye + kredi limiti)
    # @return [Money] Kullanılabilir toplam bakiye
    def available_balance
      Money.new(balance_cents + credit_limit_cents, currency)
    end
    
    # Kullanılabilir bakiye (cents)
    def available_balance_cents
      balance_cents + credit_limit_cents
    end
    
    # Sipariş için yeterli bakiye var mı?
    # @param required_cents [Integer] Gerekli miktar (cents cinsinden)
    # @return [Boolean] Yeterli bakiye varsa true
    def sufficient_balance?(required_cents)
      available_balance_cents >= required_cents
    end
    
    # Bakiye pozitif mi?
    def positive_balance?
      balance_cents > 0
    end
    
    # Bakiye negatif mi? (borçlu)
    def negative_balance?
      balance_cents < 0
    end
    
    # Kredi limitini aşmış mı?
    def over_limit?
      balance_cents < -credit_limit_cents
    end
    
    # Borç miktarı (negatif bakiye)
    def debt_amount
      return Money.new(0, currency) if positive_balance?
      Money.new(balance_cents.abs, currency)
    end
    
    # Borç miktarı (cents)
    def debt_amount_cents
      return 0 if positive_balance?
      balance_cents.abs
    end
    
    # Kredi limitini güncelle
    # @param new_limit_cents [Integer] Yeni limit (cents cinsinden)
    def update_credit_limit!(new_limit_cents)
      update!(credit_limit_cents: new_limit_cents)
    end
    
    # Bakiye özeti
    # @return [Hash] Bakiye detayları
    def summary
      {
        balance: balance.format,
        balance_cents: balance_cents,
        credit_limit: credit_limit.format,
        credit_limit_cents: credit_limit_cents,
        available_balance: available_balance.format,
        available_balance_cents: available_balance_cents,
        debt: debt_amount.format,
        debt_cents: debt_amount_cents,
        status: balance_status,
        last_transaction_at: last_transaction_at
      }
    end
    
    # Bakiye durumu
    # @return [String] 'positive', 'negative', 'over_limit'
    def balance_status
      if over_limit?
        'over_limit'
      elsif negative_balance?
        'negative'
      else
        'positive'
      end
    end
    
    private
    
    def set_defaults
      self.balance_cents ||= 0
      self.credit_limit_cents ||= 0
      self.currency ||= 'USD'
    end
    
    def update_last_transaction_at
      self.last_transaction_at = Time.current
    end
    
    def dealer_must_be_dealer_role
      return if dealer.nil?
      
      unless dealer.dealer?
        errors.add(:dealer, 'must have dealer role')
      end
    end
    
    # İşlem log'u - Transaction kaydı oluştur
    def log_transaction(type, amount_cents, note, order_id: nil)
      transactions.create!(
        transaction_type: type,
        amount_cents: amount_cents.abs,
        note: note,
        order_id: order_id
      )
      
      Rails.logger.info <<~LOG
        💰 DEALER BALANCE TRANSACTION
        ==============================
        Dealer: #{dealer.name} (#{dealer.email})
        Type: #{type.to_s.upcase}
        Amount: #{Money.new(amount_cents, currency).format}
        Balance After: #{balance.format}
        Note: #{note}
        Time: #{Time.current}
        ==============================
      LOG
    end
  end
end
