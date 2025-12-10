class HepsijetService
  require 'net/http'
  require 'json'
  require 'uri'

  DEFAULT_BASE_URL = 'https://integration-apitest.hepsijet.com'

  def initialize
    @username = Setting.find_by(key: 'hepsijet_username')&.value
    @password = Setting.find_by(key: 'hepsijet_password')&.value
    @enabled = Setting.find_by(key: 'hepsijet_enabled')&.value == 'true'
    @base_url = Setting.find_by(key: 'hepsijet_endpoint')&.value || DEFAULT_BASE_URL
  end

    def enabled?
      @enabled
    end

    def create_shipment(order)
      return unless enabled?

      token = authenticate
      return unless token

      # Hepsijet expects a specific payload. This is a best-guess structure.
      # You may need to adjust fields based on exact API docs.
      payload = {
        company_name: "MyCompany", # Should be configurable or fixed
        delivery_method: "TODAY", # or STANDARD
        receiver: {
          name: order.shipping_address&.dig('name') || order.user&.name,
          phone: order.shipping_address&.dig('phone') || order.user&.phone,
          email: order.user&.email,
          address: order.shipping_address&.dig('address_line1'),
          city: order.shipping_address&.dig('city'),
          district: order.shipping_address&.dig('state'), # Assuming state maps to district or similar
          country_code: "TR"
        },
        product: {
          product_code: order.order_number,
          product_name: "Sipariş #{order.order_number}",
          desi: 1 # Default desi, maybe calculate from order lines
        }
      }

      # Note: The actual payload structure for Hepsijet sendDeliveryOrder might differ.
      # Usually it involves an array of orders.
      
      # Let's assume a simplified payload for now and refine if we get errors or more docs.
      # Based on common Hepsijet integrations:
      request_body = [
        {
          "customerDeliveryNo": order.order_number,
          "receiverName": order.shipping_address&.dig('name') || order.user&.name,
          "receiverAddress": "#{order.shipping_address&.dig('address_line1')} #{order.shipping_address&.dig('address_line2')}",
          "receiverPhone": order.shipping_address&.dig('phone') || order.user&.phone,
          "receiverCity": order.shipping_address&.dig('city'),
          "receiverTown": order.shipping_address&.dig('state'), # District
          "receiverDistrict": order.shipping_address&.dig('state'), # Neighborhood/District
          "productCode": "PRD-#{order.id}",
          "desi": 1
        }
      ]

      response = request(:post, '/delivery/sendDeliveryOrder', token, request_body)
      
      if response['status'] == 'Success' || response['status'] == 'OK'
        # Assuming response contains the barcode or tracking number
        # The response format usually contains a list of results.
        # Let's assume we get a barcode back.
        # If not, we might need to use the order number as barcode if Hepsijet allows.
        
        # For now, let's assume we get a barcode in the response.
        # If the API doesn't return it directly, we might use the customerDeliveryNo as the reference.
        
        # Let's try to generate ZPL to verify we have a valid barcode.
        # If we sent customerDeliveryNo, maybe that's the barcode?
        # Usually Hepsijet returns a 'barcode' field.
        
        barcode = response.dig('data', 0, 'barcode')
        
        if barcode
          # Create or update Shipment
          shipment = Shipment.find_or_initialize_by(order: order)
          shipment.carrier = 'hepsijet'
          shipment.tracking_number = barcode
          shipment.status = :preparing
          shipment.save!
          
          return barcode
        end
      else
        Rails.logger.error "Hepsijet Shipment Error: #{response}"
        nil
      end
    end

    def generate_zpl_barcode(barcode)
      return unless enabled?
      token = authenticate
      return unless token

      # GET /delivery/generateZplBarcode/{barcode}/{totalParcel}
      # This endpoint returns the ZPL content directly or a JSON?
      # The docs say "generateZplBarcode/BARCODEKODU/Totalparcel değerini yazarak çıktı alınabilir"
      
      uri = URI("#{@base_url}/delivery/generateZplBarcode/#{barcode}/1")
      req = Net::HTTP::Get.new(uri)
      req['Authorization'] = "Bearer #{token}"
      
      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(req)
      end

      if res.is_a?(Net::HTTPSuccess)
        res.body # This should be the ZPL content
      else
        Rails.logger.error "Hepsijet ZPL Error: #{res.body}"
        nil
      end
    end

    private

    def authenticate
      uri = URI("#{@base_url}/auth/getToken")
      req = Net::HTTP::Post.new(uri)
      req['Content-Type'] = 'application/json'
      req.body = {
        username: @username,
        password: @password
      }.to_json

      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(req)
      end

      if res.is_a?(Net::HTTPSuccess)
        data = JSON.parse(res.body)
        data.dig('data', 'token') # Adjust based on actual response structure
      else
        Rails.logger.error "Hepsijet Auth Error: #{res.body}"
        nil
      end
    end

    def request(method, endpoint, token, body = nil)
      uri = URI("#{@base_url}#{endpoint}")
      req = method == :post ? Net::HTTP::Post.new(uri) : Net::HTTP::Get.new(uri)
      req['Content-Type'] = 'application/json'
      req['Authorization'] = "Bearer #{token}"
      req.body = body.to_json if body

      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(req)
      end

      JSON.parse(res.body)
    rescue JSON::ParserError
      { 'error' => 'Invalid JSON response', 'body' => res.body }
    end
  end
