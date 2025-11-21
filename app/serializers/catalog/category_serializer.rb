# frozen_string_literal: true

module Catalog
  class CategorySerializer
    def initialize(category, options = {})
      @category = category
      @options = options
    end

    def as_json
      {
        type: 'category',
        id: @category.id.to_s,
        attributes: {
          name: @category.name,
          slug: @category.slug,
          created_at: @category.created_at,
          updated_at: @category.updated_at
        },
        relationships: relationships,
        links: {
          self: "/api/categories/#{@category.id}"
        }
      }
    end

    def self.collection(categories, options = {})
      {
        data: categories.map { |category| new(category, options).as_json },
        meta: {
          total: categories.size
        }
      }
    end

    private

    def relationships
      rels = {}
      
      if @category.parent_id.present?
        rels[:parent] = {
          data: { type: 'category', id: @category.parent_id.to_s }
        }
      end

      if @options[:include_children] && @category.children.any?
        rels[:children] = {
          data: @category.children.map { |c| { type: 'category', id: c.id.to_s } }
        }
      end

      if @options[:include_products_count]
        rels[:products] = {
          meta: { count: @category.products.count }
        }
      end

      rels
    end
  end
end
