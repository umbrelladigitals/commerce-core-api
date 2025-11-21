class ProductOption < ApplicationRecord
  belongs_to :product, class_name: 'Catalog::Product'
  has_many :values, class_name: 'ProductOptionValue', dependent: :destroy
end
