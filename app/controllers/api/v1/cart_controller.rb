# frozen_string_literal: true

module Api
  module V1
    # Sepet yönetimi API controller'ı
    # Kullanıcının aktif sepetini yönetir (guest kullanıcılar da kullanabilir)
    class CartController < ApplicationController
      before_action :authenticate_user_optional
      before_action :find_or_create_cart, only: [:show, :add, :update_item, :remove_item, :clear]
      
      # GET /api/cart
      # Kullanıcının aktif sepetini gösterir
      def show
        calculator = ::Orders::OrderPriceCalculator.new(@cart)
        preview = calculator.preview
        
        render json: {
          data: {
            type: 'cart',
            id: @cart.id.to_s,
            attributes: {
              status: @cart.status,
              items_count: @cart.order_lines.count,
              total_quantity: @cart.total_items,
              subtotal: preview[:subtotal],
              shipping: preview[:shipping],
              tax: preview[:tax],
              total: preview[:total],
              currency: @cart.currency,
              free_shipping: preview[:free_shipping],
              payable: @cart.payable?,
              created_at: @cart.created_at,
              updated_at: @cart.updated_at
            },
            relationships: {
              items: {
                data: @cart.order_lines.map { |line| { type: 'order_lines', id: line.id.to_s } }
              }
            },
            included: @cart.order_lines.includes(:product, :variant).map do |line|
              # Get stock information
              stock = if line.variant_id
                        line.variant&.stock || 0
                      else
                        # For products without variants, we can't determine exact stock
                        # Return nil to indicate stock check is not applicable
                        nil
                      end
              
              sufficient_stock = if stock.nil?
                                  true # No stock check for products without variants
                                elsif stock >= line.quantity
                                  true
                                else
                                  false
                                end
              
              {
                type: 'order_lines',
                id: line.id.to_s,
                attributes: {
                  product_id: line.product_id,
                  product_title: line.product_title,
                  variant_id: line.variant_id,
                  variant_name: line.variant&.display_name,
                  quantity: line.quantity,
                  unit_price: line.unit_price.format,
                  total: line.total.format,
                  note: line.note,
                  stock: stock,
                  sufficient_stock: sufficient_stock
                }
              }
            end
          }
        }
      end
      
      # POST /api/cart/add
      # Sepete ürün ekler
      # Parametreler:
      #   - product_id: Ürün ID (zorunlu)
      #   - variant_id: Varyant ID (opsiyonel)
      #   - quantity: Miktar (varsayılan: 1)
      #   - note: Not (opsiyonel)
      def add
        product = ::Catalog::Product.find(params[:product_id])
        variant = params[:variant_id].present? ? ::Catalog::Variant.find(params[:variant_id]) : nil
        quantity = params[:quantity]&.to_i || 1
        
        # Aynı ürün/variant zaten sepette var mı?
        existing_line = @cart.order_lines.find_by(
          product_id: product.id,
          variant_id: variant&.id
        )
        
        begin
          if existing_line
            # Var olan satırı güncelle
            new_quantity = existing_line.quantity + quantity
            existing_line.update!(quantity: new_quantity)
            line = existing_line
          else
            # Yeni satır ekle
            line = @cart.order_lines.create!(
              product: product,
              variant: variant,
              quantity: quantity,
              note: params[:note]
            )
          end
          
          # Fiyatları yeniden hesapla
          ::Orders::OrderPriceCalculator.new(@cart).calculate!
        rescue ActiveRecord::RecordInvalid => e
          return render json: { 
            error: 'Ürün sepete eklenemedi', 
            details: e.record.errors.full_messages 
          }, status: :unprocessable_entity
        end
        
        render json: {
          message: 'Ürün sepete eklendi',
          data: {
            type: 'order_lines',
            id: line.id.to_s,
            attributes: {
              product_id: line.product_id,
              product_title: line.product_title,
              variant_id: line.variant_id,
              variant_name: line.variant&.display_name,
              quantity: line.quantity,
              unit_price: line.unit_price.format,
              total: line.total.format,
              note: line.note
            }
          },
          meta: {
            cart_total_items: @cart.total_items,
            cart_total: @cart.total.format
          }
        }, status: :created
        
      rescue ActiveRecord::RecordInvalid => e
        render json: { 
          error: 'Ürün sepete eklenemedi', 
          details: e.record.errors.full_messages 
        }, status: :unprocessable_entity
      end
      
      # PATCH /api/cart/items/:id
      # Sepetteki bir ürünün miktarını günceller
      def update_item
        line = @cart.order_lines.find(params[:id])
        line.update!(quantity: params[:quantity])
        
        ::Orders::OrderPriceCalculator.new(@cart).calculate!
        
        render json: {
          message: 'Ürün miktarı güncellendi',
          data: {
            type: 'order_lines',
            id: line.id.to_s,
            attributes: {
              quantity: line.quantity,
              unit_price: line.unit_price.format,
              total: line.total.format
            }
          }
        }
        
      rescue ActiveRecord::RecordInvalid => e
        render json: { 
          error: 'Miktar güncellenemedi', 
          details: e.record.errors.full_messages 
        }, status: :unprocessable_entity
      end
      
      # DELETE /api/cart/items/:id
      # Sepetten ürün çıkarır
      def remove_item
        line = @cart.order_lines.find(params[:id])
        line.destroy!
        
        ::Orders::OrderPriceCalculator.new(@cart).calculate!
        
        render json: {
          message: 'Ürün sepetten çıkarıldı',
          meta: {
            cart_total_items: @cart.total_items,
            cart_total: @cart.total.format
          }
        }
      end
      
      # DELETE /api/cart/clear
      # Sepeti tamamen temizler
      def clear
        @cart.order_lines.destroy_all
        ::Orders::OrderPriceCalculator.new(@cart).calculate!
        
        render json: { message: 'Sepet temizlendi' }
      end
      
      # GET /api/cart/checkout/preview
      # Checkout önizlemesi - fiyat detayları, ödeme yöntemleri
      def checkout_preview
        find_or_create_cart
        
        service = ::Orders::CheckoutService.new(@cart)
        result = service.preview
        
        if result[:success]
          render json: {
            data: {
              type: 'checkout_preview',
              attributes: result[:preview],
              payment_methods: result[:payment_methods],
              can_use_balance: result[:can_use_balance],
              dealer_balance: result[:dealer_balance]
            }
          }
        else
          render json: { error: 'Önizleme oluşturulamadı', details: result[:errors] }, 
                 status: :unprocessable_entity
        end
      end
      
      # POST /api/cart/checkout
      # Ödeme sürecini başlatır
      # Parametreler:
      #   - email: Email (guest için zorunlu)
      #   - password: Şifre (hesap oluşturmak için opsiyonel)
      #   - create_account: Boolean (hesap oluşturulsun mu?)
      #   - payment_method: 'credit_card', 'dealer_balance', 'bank_transfer', 'cash_on_delivery'
      #   - shipping_address: { name, phone, address_line1, city, postal_code, country }
      #   - billing_address: { ... } (opsiyonel, yoksa shipping ile aynı)
      #   - notes: Sipariş notu (opsiyonel)
      def checkout
        find_or_create_cart
        
        # If user is already authenticated, assign cart to user
        if current_user && @cart.user_id.nil?
          @cart.update!(user: current_user)
          session.delete(:guest_cart_id)
        end
        
        # Guest checkout için kullanıcı oluştur veya bul
        @newly_created_user = nil # Track if we created a new user for auto-login
        
        # If user is already authenticated, skip user creation/validation
        if @cart.user_id.nil? && current_user.nil?
          email = params[:email]
          password = params[:password]
          create_account = params[:create_account]
          
          unless email.present?
            return render json: { 
              success: false, 
              error: 'Email gereklidir' 
            }, status: :unprocessable_entity
          end
          
          # Email ile kullanıcı var mı kontrol et
          existing_user = User.find_by(email: email)
          
          if existing_user
            # Kullanıcı varsa ama şifre girilmemişse hata
            unless password.present?
              return render json: {
                success: false,
                error: 'Bu email ile kayıtlı bir hesap var. Lütfen şifrenizi girin.',
                requires_password: true
              }, status: :unprocessable_entity
            end
            
            # Şifre kontrolü
            unless existing_user.valid_password?(password)
              return render json: {
                success: false,
                error: 'Email veya şifre hatalı'
              }, status: :unauthorized
            end
            
            # Mevcut kullanıcıyı kullan
            user = existing_user
            # If guest is logging in (no current_user), provide token for auto-login
            @newly_created_user = existing_user unless current_user
          elsif create_account
            # Yeni hesap oluştur
            if password.blank?
              return render json: {
                success: false,
                error: 'Hesap oluşturmak için şifre gereklidir'
              }, status: :unprocessable_entity
            end
            
            # Name field'ı shipping address'ten veya email'den al
            user_name = params.dig(:shipping_address, :name).presence || email.split('@').first.capitalize
            
            user = User.new(
              email: email,
              name: user_name,
              password: password,
              password_confirmation: password,
              role: :customer
            )
            
            unless user.save
              return render json: {
                success: false,
                error: 'Hesap oluşturulamadı',
                errors: user.errors.full_messages
              }, status: :unprocessable_entity
            end
            
            # Track new user for auto-login
            @newly_created_user = user
          else
            # Guest olarak devam et - geçici kullanıcı oluştur
            # Name field'ı email'in ilk kısmından oluştur
            guest_name = email.split('@').first.capitalize
            
            user = User.create!(
              email: email,
              name: guest_name,
              password: SecureRandom.hex(16), # Random password
              role: :customer
            )
            
            # Track new user for auto-login
            @newly_created_user = user
          end
          
          # Cart'ı kullanıcıya ata
          @cart.update!(user: user)
          session.delete(:guest_cart_id)
        end
        
        checkout_params = {
          payment_method: params[:payment_method],
          shipping_address: params[:shipping_address],
          billing_address: params[:billing_address],
          notes: params[:notes],
          use_different_billing: params[:use_different_billing]
        }
        
        service = ::Orders::CheckoutService.new(@cart, checkout_params)
        result = service.process
        
        if result[:success]
          # Clear cart session after successful checkout
          # This ensures a new cart is created for next order
          session.delete(:guest_cart_id)
          
          response_data = {
            success: true,
            message: result[:message] || 'İşlem başarılı',
            data: {
              type: 'order',
              id: result[:order].id.to_s,
              attributes: {
                order_number: result[:order].order_number,
                status: result[:order].status,
                payment_method: result[:payment_method],
                total: result[:order].total.format,
                paid_at: result[:order].paid_at
              }
            },
            payment_data: result[:payment_data],
            next_step: result[:next_step]
          }
          
          # If a new user was created (guest checkout or account creation), return auth token
          # This allows frontend to authenticate and view the order details
          if @newly_created_user && !current_user
            token = Warden::JWTAuth::UserEncoder.new.call(@newly_created_user, :user, nil).first
            response_data[:auth] = {
              token: token,
              user: {
                id: @newly_created_user.id,
                email: @newly_created_user.email,
                name: @newly_created_user.name,
                role: @newly_created_user.role,
                created_at: @newly_created_user.created_at.iso8601,
                updated_at: @newly_created_user.updated_at.iso8601
              }
            }
          end
          
          Rails.logger.info "Final response_data keys: #{response_data.keys.inspect}"
          Rails.logger.info "Response includes auth: #{response_data.key?(:auth)}"
          
          render json: response_data, status: :ok
        else
          render json: { 
            success: false,
            error: 'Checkout işlemi başarısız', 
            errors: result[:errors] 
          }, status: :unprocessable_entity
        end
        
      rescue StandardError => e
        Rails.logger.error "Checkout hatası: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render json: { 
          success: false,
          error: 'Ödeme başlatılamadı', 
          details: e.message 
        }, status: :unprocessable_entity
      end
      
      private
      
      # Kullanıcının veya guest'in aktif sepetini bul veya oluştur
      def find_or_create_cart
        if current_user
          # Authenticated user - kullanıcının sepetini bul/oluştur
          @cart = current_user.orders.find_or_create_by!(status: :cart) do |order|
            order.currency = 'TRY'
            order.total_cents = 0
            order.subtotal_cents = 0
            order.tax_cents = 0
            order.shipping_cents = 0
            order.discount_cents = 0
          end
          
          # Eğer session'da guest cart varsa, merge et
          merge_guest_cart_if_exists
        else
          # Guest user - session-based cart
          find_or_create_guest_cart
        end
      end
      
      # Guest cart'ı header veya session'dan bul veya oluştur
      # Best practice: X-Guest-Cart-Id header ile cart tracking (localStorage persistence için)
      def find_or_create_guest_cart
        # Priority: Header (from localStorage) > Session (fallback)
        cart_id = request.headers['X-Guest-Cart-Id'].presence || session[:guest_cart_id]
        
        if cart_id
          @cart = ::Orders::Order.find_by(id: cart_id, status: :cart, user_id: nil)
        end
        
        unless @cart
          @cart = ::Orders::Order.create!(
            status: :cart,
            currency: 'TRY',
            total_cents: 0,
            subtotal_cents: 0,
            tax_cents: 0,
            shipping_cents: 0,
            discount_cents: 0,
            user_id: nil
          )
          # Save to both session (backup) and response header (for frontend)
          session[:guest_cart_id] = @cart.id
          response.headers['X-Guest-Cart-Id'] = @cart.id.to_s
        else
          # If cart exists, always send the ID back in response header
          response.headers['X-Guest-Cart-Id'] = @cart.id.to_s
        end
        
        @cart
      end
      
      # Guest cart'ı kullanıcı cart'ına merge et
      def merge_guest_cart_if_exists
        guest_cart_id = session[:guest_cart_id]
        return unless guest_cart_id
        
        guest_cart = ::Orders::Order.find_by(id: guest_cart_id, status: :cart, user_id: nil)
        return unless guest_cart
        
        # Guest cart'taki itemları kullanıcı cart'ına taşı
        guest_cart.order_lines.each do |line|
          existing = @cart.order_lines.find_by(
            product_id: line.product_id,
            variant_id: line.variant_id
          )
          
          if existing
            existing.update(quantity: existing.quantity + line.quantity)
          else
            line.update(order_id: @cart.id)
          end
        end
        
        # Fiyatları yeniden hesapla
        ::Orders::OrderPriceCalculator.new(@cart).calculate!
        
        # Guest cart'ı sil
        guest_cart.destroy
        session.delete(:guest_cart_id)
      end
      
      # Optional authentication - tries to authenticate but doesn't fail if token missing/invalid
      def authenticate_user_optional
        token = request.headers['Authorization']&.split(' ')&.last
        
        return unless token # No token provided, continue as guest
        
        begin
          secret_key = Rails.application.credentials.devise_jwt_secret_key || Rails.application.secret_key_base
          decoded = JWT.decode(token, secret_key, true, { algorithm: 'HS256' })
          payload = decoded.first
          
          @current_user = User.find_by(id: payload['sub'])
        rescue JWT::ExpiredSignature, JWT::DecodeError => e
          # Token invalid/expired, continue as guest
          Rails.logger.info "Optional auth failed: #{e.message}"
          @current_user = nil
        end
      end

      # Checkout validasyon hatalarını topla
      def checkout_validation_errors
        errors = []
        errors << 'Sepet boş' if @cart.order_lines.empty?
        errors << 'Bazı ürünler stokta yok' unless @cart.all_items_in_stock?
        errors
      end
    end
  end
end
