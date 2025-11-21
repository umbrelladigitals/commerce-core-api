# frozen_string_literal: true

module Catalog
  class Category < ApplicationRecord
    self.table_name = 'categories'

    # Associations
    belongs_to :parent, class_name: 'Catalog::Category', optional: true
    has_many :children, class_name: 'Catalog::Category', foreign_key: :parent_id, dependent: :destroy
    has_many :products, class_name: 'Catalog::Product', dependent: :nullify

    # Validations
    validates :name, presence: true
    validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }

    # Callbacks
    before_validation :generate_slug, if: -> { slug.blank? }

    # Scopes
    scope :root_categories, -> { where(parent_id: nil) }
    scope :active_products, -> { joins(:products).where(products: { active: true }).distinct }

    # Instance methods
    def root?
      parent_id.nil?
    end

    def leaf?
      children.empty?
    end

    def ancestors
      return [] if root?
      [parent] + parent.ancestors
    end

    def descendants
      children + children.flat_map(&:descendants)
    end

    private

    def generate_slug
      self.slug = name.to_s.parameterize
    end
  end
end
