# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::Reports::SalesController, type: :controller do
  let(:user) { create(:user, :admin) }
  let(:dealer) { create(:user, :dealer) }
  let(:product1) { create(:product, 'Catalog::Product', title: 'Product A', sku: 'SKU-A') }
  let(:product2) { create(:product, 'Catalog::Product', title: 'Product B', sku: 'SKU-B') }
  
  before do
    sign_in user
    
    # Create some orders for testing
    order1 = create(:order, user: dealer, status: :paid, created_at: 3.days.ago)
    create(:order_item, 'Orders::OrderItem', order: order1, product: product1, 
           quantity: 2, price_cents: 10000, total_cents: 20000)
    
    order2 = create(:order, user: dealer, status: :paid, created_at: 1.day.ago)
    create(:order_item, 'Orders::OrderItem', order: order2, product: product2, 
           quantity: 1, price_cents: 15000, total_cents: 15000)
  end
  
  describe 'GET #index' do
    context 'with JSON format' do
      it 'returns sales report' do
        get :index, format: :json
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        
        expect(json['success']).to be true
        expect(json['data']['summary']).to be_present
        expect(json['data']['breakdown']).to be_an(Array)
      end
      
      it 'filters by date range' do
        get :index, params: { 
          start_date: 2.days.ago.to_date.to_s,
          end_date: Date.today.to_s
        }, format: :json
        
        expect(response).to have_http_status(:ok)
      end
      
      it 'filters by dealer_id' do
        get :index, params: { dealer_id: dealer.id }, format: :json
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data']['summary']['orders_count']).to eq(2)
      end
      
      it 'returns error for invalid date format' do
        get :index, params: { start_date: 'invalid' }, format: :json
        
        expect(response).to have_http_status(:bad_request)
      end
    end
    
    context 'with CSV format' do
      it 'returns CSV file' do
        get :index, format: :csv
        
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('text/csv')
        expect(response.headers['Content-Disposition']).to include('attachment')
        expect(response.headers['Content-Disposition']).to include('sales_report')
      end
      
      it 'includes correct CSV headers' do
        get :index, format: :csv
        
        csv_content = response.body
        expect(csv_content).to include('Product ID')
        expect(csv_content).to include('Product Title')
        expect(csv_content).to include('Quantity Sold')
        expect(csv_content).to include('Revenue')
      end
    end
  end
end
