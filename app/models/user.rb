class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :jwt_authenticatable,
         jwt_revocation_strategy: JwtDenylist

  # Enums
  enum role: { customer: 0, admin: 1, dealer: 2, manufacturer: 3, marketer: 4 }

  # Associations
  has_many :orders, class_name: 'Orders::Order', dependent: :destroy
  
  # B2B Associations (only for dealers)
  has_many :dealer_discounts, class_name: 'B2b::DealerDiscount', foreign_key: :dealer_id, dependent: :destroy
  has_one :dealer_balance, class_name: 'B2b::DealerBalance', foreign_key: :dealer_id, dependent: :destroy
  
  # Admin Associations
  has_many :quotes, dependent: :destroy # Kendisine yapılan teklifler
  has_many :created_quotes, class_name: 'Quote', foreign_key: 'created_by_id', dependent: :nullify # Admin olarak oluşturduğu teklifler
  has_many :admin_notes, foreign_key: 'author_id', dependent: :destroy # Admin olarak yazdığı notlar
  has_many :notes_about, class_name: 'AdminNote', as: :related, dependent: :destroy # Kendisi hakkında yazılan notlar

  # Validations
  validates :name, presence: true
  
  # Callbacks
  after_create :create_dealer_balance_if_dealer
  
  # Dealer için özel indirim var mı kontrol et
  def has_discount_for?(product)
    return false unless dealer?
    dealer_discounts.active.exists?(product_id: product.id)
  end
  
  # Dealer'ın bir ürün için indirimini getir
  def discount_for(product)
    return nil unless dealer?
    dealer_discounts.active.find_by(product_id: product.id)
  end
  
  # Dealer bakiyesi yoksa oluştur
  def ensure_dealer_balance!
    return unless dealer?
    dealer_balance || create_dealer_balance!(currency: 'USD')
  end
  
  # Set default role
  after_initialize :set_default_role, if: :new_record?

  # Generate JWT token
  def generate_jwt
    JWT.encode(
      {
        sub: id,
        email: email,
        role: role,
        scp: 'user',
        exp: 7.days.from_now.to_i
      },
      Rails.application.credentials.devise_jwt_secret_key || Rails.application.secret_key_base
    )
  end

  private

  def set_default_role
    self.role ||= :customer
  end
  
  # Dealer ise otomatik bakiye oluştur
  def create_dealer_balance_if_dealer
    return unless dealer?
    create_dealer_balance!(currency: 'USD', balance_cents: 0, credit_limit_cents: 0)
  end
end
