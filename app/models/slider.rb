class Slider < ApplicationRecord
  # Validations
  validates :title, presence: true
  validates :display_order, presence: true, numericality: { only_integer: true }
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(display_order: :asc) }
  
  # Default scope
  default_scope { ordered }
end
