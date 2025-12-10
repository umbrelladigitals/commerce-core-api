module Payment
  class IyzicoService
    def initialize
      @options = self.class.get_options
    end

    def self.get_options
      options = Iyzipay::Options.new
      options.api_key = Setting.get('iyzico_api_key', ENV['IYZICO_API_KEY'])
      options.secret_key = Setting.get('iyzico_secret_key', ENV['IYZICO_SECRET_KEY'])
      options.base_url = Setting.get('iyzico_base_url', ENV['IYZICO_BASE_URL'])
      options
    end

    def initialize_checkout(order, callback_url)
      full_name = order.user&.name || 'Misafir Kullanıcı'
      name_parts = full_name.split(' ')
      buyer_name = name_parts.first
      buyer_surname = name_parts.drop(1).join(' ')
      buyer_surname = 'Kullanıcı' if buyer_surname.blank?
      
      request = {
        locale: Iyzipay::Model::Locale::TR,
        conversationId: order.id.to_s,
        price: order.total.to_s,
        paidPrice: order.total.to_s,
        currency: Iyzipay::Model::Currency::TRY,
        basketId: order.id.to_s,
        paymentGroup: Iyzipay::Model::PaymentGroup::PRODUCT,
        callbackUrl: callback_url,
        enabledInstallments: [2, 3, 6, 9],
        buyer: {
          id: order.user_id.to_s,
          name: buyer_name,
          surname: buyer_surname,
          gsmNumber: order.user&.phone || '+905555555555',
          email: order.user&.email || 'guest@example.com',
          identityNumber: '11111111111',
          lastLoginDate: Time.now.strftime("%Y-%m-%d %H:%M:%S"),
          registrationDate: order.user&.created_at&.strftime("%Y-%m-%d %H:%M:%S") || Time.now.strftime("%Y-%m-%d %H:%M:%S"),
          registrationAddress: format_address(order.billing_address),
          ip: '85.34.78.112',
          city: order.billing_address['city'] || 'Istanbul',
          country: order.billing_address['country'] || 'Turkey',
          zipCode: order.billing_address['zip_code'] || '34732'
        },
        shippingAddress: {
          contactName: order.shipping_address['contact_name'] || "#{buyer_name} #{buyer_surname}",
          city: order.shipping_address['city'] || 'Istanbul',
          country: order.shipping_address['country'] || 'Turkey',
          address: format_address(order.shipping_address),
          zipCode: order.shipping_address['zip_code'] || '34742'
        },
        billingAddress: {
          contactName: order.billing_address['contact_name'] || "#{buyer_name} #{buyer_surname}",
          city: order.billing_address['city'] || 'Istanbul',
          country: order.billing_address['country'] || 'Turkey',
          address: format_address(order.billing_address),
          zipCode: order.billing_address['zip_code'] || '34742'
        },
        basketItems: order.order_lines.map do |line|
          {
            id: line.product_id.to_s,
            name: line.product&.title || 'Urun',
            category1: 'Genel',
            itemType: Iyzipay::Model::BasketItemType::PHYSICAL,
            price: line.total.to_s
          }
        end
      }

      # Calculate total basket price to ensure it matches paidPrice
      basket_total = request[:basketItems].sum { |item| item[:price].to_f }
      
      # If there is a difference (shipping, tax, etc.)
      diff = request[:price].to_f - basket_total
      
      if diff.abs > 0.01
        if diff > 0
          request[:basketItems] << {
            id: 'Shipping-Tax',
            name: 'Kargo ve Vergi',
            category1: 'Hizmet',
            itemType: Iyzipay::Model::BasketItemType::VIRTUAL,
            price: sprintf('%.2f', diff)
          }
        end
      end

      Rails.logger.info "Iyzico Checkout Request: #{request.inspect}"
      response = Iyzipay::Model::CheckoutFormInitialize.new.create(request, @options)
      Rails.logger.info "Iyzico Checkout Response: #{response}"
      JSON.parse(response)
    end

    def process_direct_payment(order, card_details)
      # Ensure indifferent access
      card_details = card_details.with_indifferent_access if card_details.respond_to?(:with_indifferent_access)
      
      full_name = order.user&.name || 'Misafir Kullanıcı'
      name_parts = full_name.split(' ')
      buyer_name = name_parts.first
      buyer_surname = name_parts.drop(1).join(' ')
      buyer_surname = 'Kullanıcı' if buyer_surname.blank?

      request = {
        locale: Iyzipay::Model::Locale::TR,
        conversationId: order.id.to_s,
        price: order.total.to_s,
        paidPrice: order.total.to_s,
        currency: Iyzipay::Model::Currency::TRY,
        installment: 1,
        basketId: order.id.to_s,
        paymentChannel: Iyzipay::Model::PaymentChannel::WEB,
        paymentGroup: Iyzipay::Model::PaymentGroup::PRODUCT,
        paymentCard: {
          cardHolderName: card_details[:card_holder_name],
          cardNumber: card_details[:card_number],
          expireMonth: card_details[:expire_month],
          expireYear: card_details[:expire_year],
          cvc: card_details[:cvc],
          registerCard: 0
        },
        buyer: {
          id: order.user_id.to_s,
          name: buyer_name,
          surname: buyer_surname,
          gsmNumber: order.user&.phone || '+905555555555',
          email: order.user&.email || 'guest@example.com',
          identityNumber: '11111111111',
          lastLoginDate: Time.now.strftime("%Y-%m-%d %H:%M:%S"),
          registrationDate: order.user&.created_at&.strftime("%Y-%m-%d %H:%M:%S") || Time.now.strftime("%Y-%m-%d %H:%M:%S"),
          registrationAddress: format_address(order.billing_address),
          ip: '85.34.78.112',
          city: order.billing_address['city'] || 'Istanbul',
          country: order.billing_address['country'] || 'Turkey',
          zipCode: order.billing_address['zip_code'] || '34732'
        },
        shippingAddress: {
          contactName: order.shipping_address['contact_name'] || "#{buyer_name} #{buyer_surname}",
          city: order.shipping_address['city'] || 'Istanbul',
          country: order.shipping_address['country'] || 'Turkey',
          address: format_address(order.shipping_address),
          zipCode: order.shipping_address['zip_code'] || '34742'
        },
        billingAddress: {
          contactName: order.billing_address['contact_name'] || "#{buyer_name} #{buyer_surname}",
          city: order.billing_address['city'] || 'Istanbul',
          country: order.billing_address['country'] || 'Turkey',
          address: format_address(order.billing_address),
          zipCode: order.billing_address['zip_code'] || '34742'
        },
        basketItems: order.order_lines.map do |line|
          {
            id: line.product_id.to_s,
            name: line.product&.title || 'Urun',
            category1: 'Genel',
            itemType: Iyzipay::Model::BasketItemType::PHYSICAL,
            price: line.total.to_s
          }
        end
      }

      # Calculate total basket price to ensure it matches paidPrice
      basket_total = request[:basketItems].sum { |item| item[:price].to_f }
      
      # If there is a mismatch due to shipping/tax/discounts not being in basket items
      # We need to add them as items or adjust prices.
      # Iyzico requires sum(basketItems.price) == price
      
      # Check if there is a difference
      diff = request[:price].to_f - basket_total
      
      if diff.abs > 0.01
        # Add shipping/tax as a separate item if positive
        if diff > 0
          request[:basketItems] << {
            id: 'Shipping-Tax',
            name: 'Kargo ve Vergi',
            category1: 'Hizmet',
            itemType: Iyzipay::Model::BasketItemType::VIRTUAL,
            price: sprintf('%.2f', diff)
          }
        end
      end

      response = Iyzipay::Model::Payment.new.create(request, @options)
      JSON.parse(response)
    end

    private

    def format_address(address_hash)
      return 'Adres yok' if address_hash.blank?
      [address_hash['address_line1'], address_hash['address_line2']].compact.join(' ')
    end
  end
end
