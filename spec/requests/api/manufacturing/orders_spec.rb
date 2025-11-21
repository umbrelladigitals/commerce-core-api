# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::Manufacturing::Orders', type: :request do
  let(:manufacturer) { create(:user, :manufacturer) }
  let(:dealer) { create(:user, :dealer) }
  let(:customer) { create(:user) }
  let!(:order) { create(:order, user: customer, production_status: 'pending') }
  
  # Authentication helper - Generate JWT token for user
  def auth_headers(user)
    # Generate JWT token directly using Warden's JWT strategy
    token = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
    
    {
      'Authorization' => "Bearer #{token}"
    }
  end
  
  describe 'GET /api/v1/manufacturing/orders' do
    context 'when user is manufacturer' do
      it 'returns list of orders without price information' do
        get '/api/v1/manufacturing/orders', headers: auth_headers(manufacturer)
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        
        expect(json['data']).to be_an(Array)
        first_order = json['data'].first
        
        # Fiyat bilgileri olmamalı
        expect(first_order['attributes']).not_to have_key('total_cents')
        expect(first_order['attributes']).not_to have_key('subtotal_cents')
        expect(first_order['attributes']).not_to have_key('tax_cents')
        expect(first_order['attributes']).not_to have_key('shipping_cents')
        
        # Temel bilgiler olmalı
        expect(first_order['attributes']).to have_key('order_number')
        expect(first_order['attributes']).to have_key('production_status')
        expect(first_order['attributes']).to have_key('status')
      end
    end
    
    context 'when user is not manufacturer' do
      it 'returns unauthorized' do
        get '/api/v1/manufacturing/orders', headers: auth_headers(dealer)
        
        expect(response).to have_http_status(:forbidden)
      end
    end
    
    context 'when user is not authenticated' do
      it 'returns unauthorized or redirect' do
        get '/api/v1/manufacturing/orders'
        
        # Devise default behavior: 302 redirect or 401 unauthorized
        expect([302, 401]).to include(response.status)
      end
    end
  end
  
  describe 'GET /api/v1/manufacturing/orders/:id' do
    context 'when user is manufacturer' do
      it 'returns order details without price information' do
        get "/api/v1/manufacturing/orders/#{order.id}", headers: auth_headers(manufacturer)
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        
        order_data = json['data']
        
        # Fiyat bilgileri olmamalı
        expect(order_data['attributes']).not_to have_key('total_cents')
        expect(order_data['attributes']).not_to have_key('subtotal_cents')
        
        # Temel bilgiler olmalı
        expect(order_data['attributes']['production_status']).to eq('pending')
        expect(order_data['id']).to eq(order.id.to_s)
      end
    end
    
    context 'when user is not manufacturer' do
      it 'returns forbidden' do
        get "/api/v1/manufacturing/orders/#{order.id}", headers: auth_headers(customer)
        
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
  
  describe 'PATCH /api/v1/manufacturing/orders/:id/production_status' do
    context 'when user is manufacturer' do
      it 'updates production status and creates log' do
        expect {
          patch "/api/v1/manufacturing/orders/#{order.id}/production_status",
                params: { production_status: 'in_production' },
                headers: auth_headers(manufacturer)
        }.to change(OrderStatusLog, :count).by(1)
        
        expect(response).to have_http_status(:ok)
        
        order.reload
        expect(order.production_status).to eq('in_production')
        
        # Log kaydını kontrol et
        log = order.status_logs.last
        expect(log.from_status).to eq('pending')
        expect(log.to_status).to eq('in_production')
        expect(log.user_id).to eq(manufacturer.id)
        expect(log.changed_at).to be_present
      end
      
      it 'returns error for invalid status' do
        patch "/api/v1/manufacturing/orders/#{order.id}/production_status",
              params: { production_status: 'invalid_status' },
              headers: auth_headers(manufacturer)
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Invalid production status')
        expect(json['valid_statuses']).to include('pending', 'in_production', 'ready', 'shipped')
      end
      
      it 'transitions through all statuses correctly' do
        headers = auth_headers(manufacturer)
        
        # pending -> in_production
        patch "/api/v1/manufacturing/orders/#{order.id}/production_status",
              params: { production_status: 'in_production' },
              headers: headers
        expect(response).to have_http_status(:ok)
        
        # in_production -> ready
        patch "/api/v1/manufacturing/orders/#{order.id}/production_status",
              params: { production_status: 'ready' },
              headers: headers
        expect(response).to have_http_status(:ok)
        
        # ready -> shipped
        patch "/api/v1/manufacturing/orders/#{order.id}/production_status",
              params: { production_status: 'shipped' },
              headers: headers
        expect(response).to have_http_status(:ok)
        
        order.reload
        expect(order.production_status).to eq('shipped')
        expect(order.status_logs.count).to eq(3)
      end
    end
    
    context 'when user is not manufacturer' do
      it 'returns forbidden' do
        patch "/api/v1/manufacturing/orders/#{order.id}/production_status",
              params: { production_status: 'in_production' },
              headers: auth_headers(dealer)
        
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
