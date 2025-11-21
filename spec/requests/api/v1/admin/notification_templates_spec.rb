# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Admin::NotificationTemplates', type: :request do
  let(:admin) { create(:user, role: :admin) }
  let(:customer) { create(:user, role: :customer) }
  
  def auth_headers(user)
    token = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
    { 'Authorization' => "Bearer #{token}" }
  end
  
  describe 'GET /api/v1/admin/notification_templates' do
    context 'when user is admin' do
      it 'returns list of templates' do
        create(:notification_template, name: 'test_template')
        
        get '/api/v1/admin/notification_templates', headers: auth_headers(admin)
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data']).to be_an(Array)
        expect(json['data'].first['name']).to eq('test_template')
      end
    end
    
    context 'when user is not admin' do
      it 'returns forbidden' do
        get '/api/v1/admin/notification_templates', headers: auth_headers(customer)
        
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
  
  describe 'POST /api/v1/admin/notification_templates' do
    context 'when user is admin' do
      it 'creates a new template' do
        template_params = {
          notification_template: {
            name: 'new_template',
            channel: 'email',
            subject: 'Test Subject',
            body: 'Test Body {{customer_name}}'
          }
        }
        
        expect {
          post '/api/v1/admin/notification_templates',
               params: template_params,
               headers: auth_headers(admin)
        }.to change(NotificationTemplate, :count).by(1)
        
        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['data']['name']).to eq('new_template')
      end
    end
  end
end
