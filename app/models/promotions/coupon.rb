class Promotions::Coupon < ApplicationRecord
  self.table_name = 'promotions_coupons'

  enum :discount_type, { percentage: 0, fixed_amount: 1 }

  monetize :min_order_amount_cents, as: :min_order_amount, allow_nil: true

  validates :code, presence: true, uniqueness: { case_sensitive: false }
  validates :value, presence: true, numericality: { greater_than: 0 }
  validates :discount_type, presence: true

  scope :active, -> { where(active: true).where('starts_at <= ? AND ends_at >= ?', Time.current, Time.current) }

  def applicable?(order)
    return false unless active?
    return false if starts_at && starts_at > Time.current
    return false if ends_at && ends_at < Time.current
    return false if usage_limit && usage_count >= usage_limit
    return false if min_order_amount_cents && order.subtotal_cents < min_order_amount_cents

    true
  end

  def calculate_discount(amount_cents)
    if percentage?
      (amount_cents * (value / 100.0)).round
    else
      # Fixed amount is stored as decimal, assume it represents currency units (e.g. 100.0 = 100 TL)
      # If value is 100, and we want cents, we multiply by 100? 
      # Or should we store value_cents? 
      # The migration used decimal :value. Let's assume it's the raw value.
      # If fixed_amount, value 50.0 means 50.00 TL.
      (value * 100).to_i
    end
  end

  def increment_usage!
    increment!(:usage_count)
  end
end
