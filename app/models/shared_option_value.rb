class SharedOptionValue < ApplicationRecord
  belongs_to :shared_option
  
  monetize :price_cents, as: :price

  validates :name, presence: true, uniqueness: { scope: :shared_option_id }
  validates :price_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :price_mode, presence: true, inclusion: { 
    in: %w[flat per_unit],
    message: "%{value} is not a valid price mode"
  }
end
