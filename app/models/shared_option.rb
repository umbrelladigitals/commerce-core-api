class SharedOption < ApplicationRecord
  has_many :values, class_name: 'SharedOptionValue', dependent: :destroy
  
  validates :name, presence: true, uniqueness: true
  validates :option_type, presence: true, inclusion: { in: %w[select radio checkbox color] }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  
  accepts_nested_attributes_for :values, allow_destroy: true
end
