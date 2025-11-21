# frozen_string_literal: true

module Sluggable
  extend ActiveSupport::Concern

  TURKISH_CHAR_MAP = {
    'ç' => 'c', 'Ç' => 'C',
    'ğ' => 'g', 'Ğ' => 'G',
    'ı' => 'i', 'I' => 'I', 'İ' => 'I',
    'ö' => 'o', 'Ö' => 'O',
    'ş' => 's', 'Ş' => 'S',
    'ü' => 'u', 'Ü' => 'U'
  }.freeze

  included do
    before_validation :generate_slug, if: -> { slug.blank? && respond_to?(:title) }
    validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }
  end

  class_methods do
    def find_by_slug!(slug)
      find_by!(slug: slug)
    end
  end

  private

  def generate_slug
    return if title.blank?

    base_slug = slugify(title)
    self.slug = ensure_unique_slug(base_slug)
  end

  def slugify(text)
    # Convert Turkish characters to English
    normalized = text.chars.map { |char| TURKISH_CHAR_MAP[char] || char }.join

    # Convert to lowercase and replace spaces/special chars with hyphens
    normalized.downcase
              .gsub(/[^a-z0-9\s-]/, '') # Remove special characters
              .gsub(/\s+/, '-')          # Replace spaces with hyphens
              .gsub(/-+/, '-')           # Replace multiple hyphens with single
              .gsub(/^-|-$/, '')         # Remove leading/trailing hyphens
  end

  def ensure_unique_slug(base_slug)
    slug = base_slug
    counter = 1

    while self.class.where(slug: slug).where.not(id: id).exists?
      slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    slug
  end
end
