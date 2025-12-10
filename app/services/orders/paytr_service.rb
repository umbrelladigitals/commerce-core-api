# frozen_string_literal: true

require 'net/http'
require 'digest'
require 'base64'
require 'openssl'

module Orders
  # PayTR ödeme sağlayıcı entegrasyonu
  # PayTR API ile iletişim ve token oluşturma işlemlerini yönetir
  class PaytrService
    BASE_URL = "https://www.paytr.com/odeme/api/get-token"
  
  attr_reader :order
  
  def initialize(order)
    @order = order
  end
  
  # PayTR ödeme tokeni oluşturur
  # @return [Hash] PayTR token ve ödeme bilgileri
  # @raise [StandardError] Token oluşturma hatası
  def create_payment_token
    validate_env_variables!
    
    user_ip = get_user_ip
    merchant_id = ENV["PAYTR_MERCHANT_ID"]
    merchant_key = ENV["PAYTR_MERCHANT_KEY"]
    merchant_salt = ENV["PAYTR_MERCHANT_SALT"]
    
    email = @order.user.email
    payment_amount = @order.total_cents # Kuruş cinsinden
    merchant_oid = "ORDER-#{@order.id}" # Benzersiz sipariş ID
    
    # Kullanıcı sepeti (Base64 encode)
    user_basket = build_user_basket
    
    # Başarılı/başarısız ödeme için yönlendirme URL'leri
    merchant_ok_url = "#{base_callback_url}/success"
    merchant_fail_url = "#{base_callback_url}/fail"
    
    # PayTR token oluşturma (HMAC-SHA256)
    hash_str = "#{merchant_id}#{user_ip}#{merchant_oid}#{email}#{payment_amount}#{user_basket}no_installment0#{merchant_ok_url}#{merchant_fail_url}"
    paytr_token = generate_token(hash_str, merchant_key, merchant_salt)
    
    # API'ye POST isteği gönder
    response = send_token_request(
      merchant_id: merchant_id,
      user_ip: user_ip,
      merchant_oid: merchant_oid,
      email: email,
      payment_amount: payment_amount,
      user_basket: user_basket,
      merchant_ok_url: merchant_ok_url,
      merchant_fail_url: merchant_fail_url,
      paytr_token: paytr_token,
      user_name: @order.user.full_name || @order.user.email,
      user_phone: @order.user.phone || "0000000000"
    )
    
    parse_token_response(response)
  end
  
  # PayTR callback'ten gelen imzayı doğrular
  # @param params [Hash] Callback parametreleri
  # @return [Boolean] İmza geçerli mi?
  def self.verify_callback(params)
    received_hash = params[:hash]
    merchant_oid = params[:merchant_oid]
    status = params[:status]
    total_amount = params[:total_amount]
    
    hash_str = "#{merchant_oid}#{ENV['PAYTR_MERCHANT_SALT']}#{status}#{total_amount}"
    expected_hash = Base64.strict_encode64(OpenSSL::HMAC.digest("sha256", ENV['PAYTR_MERCHANT_KEY'], hash_str))
    
    expected_hash == received_hash
  end
  
  private
  
  def validate_env_variables!
    required_vars = %w[PAYTR_MERCHANT_ID PAYTR_MERCHANT_KEY PAYTR_MERCHANT_SALT]
    missing_vars = required_vars.select { |var| ENV[var].blank? }
    
    if missing_vars.any?
      raise StandardError, "PayTR yapılandırması eksik: #{missing_vars.join(', ')}"
    end
  end
  
  def get_user_ip
    # Gerçek uygulamada request'ten IP alınmalı
    # Controller'dan inject edilebilir
    "127.0.0.1"
  end
  
  def base_callback_url
    # Production'da gerçek domain kullanılmalı
    ENV["PAYTR_CALLBACK_URL"] || "https://yourdomain.com/api/payment/callback"
  end
  
  # Sepet içeriğini PayTR formatında oluşturur
  def build_user_basket
    basket_items = @order.order_lines.map do |line|
      [
        line.product.title,                    # Ürün adı
        (line.price.cents / 100.0).to_s,     # Ürün fiyatı (TL)
        line.quantity                         # Adet
      ]
    end
    
    Base64.strict_encode64(basket_items.to_json)
  end
  
  # HMAC-SHA256 token oluşturur
  def generate_token(hash_str, merchant_key, merchant_salt)
    hash_str_with_salt = hash_str + merchant_salt
    Base64.strict_encode64(OpenSSL::HMAC.digest("sha256", merchant_key, hash_str_with_salt))
  end
  
  # PayTR API'ye token isteği gönderir
  def send_token_request(params)
    uri = URI.parse(BASE_URL)
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data(params)
    
    response = http.request(request)
    response.body
  end
  
  # API yanıtını parse eder
  def parse_token_response(response_body)
    data = JSON.parse(response_body)
    
    if data["status"] == "success"
      {
        success: true,
        token: data["token"],
        iframe_url: "https://www.paytr.com/odeme/guvenli/#{data['token']}"
      }
    else
      {
        success: false,
        error: data["reason"] || "Token oluşturulamadı"
      }
    end
  rescue JSON::ParserError => e
    Rails.logger.error "PayTR API yanıtı parse edilemedi: #{e.message}"
    { success: false, error: "API yanıtı geçersiz" }
  end
  end
end
