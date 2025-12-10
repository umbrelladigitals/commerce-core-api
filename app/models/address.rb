class Address < ApplicationRecord
  belongs_to :user

  enum :address_type, { shipping: 0, billing: 1, both: 2 }

  validates :title, :name, :phone, :address_line1, :city, :country, presence: true
end
