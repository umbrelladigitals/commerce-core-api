# frozen_string_literal: true

module Api
  module Admin
    # Admin settings management
    class SettingsController < ApplicationController
      before_action :authenticate_user!
      before_action :ensure_admin
      
      # GET /api/admin/settings
      def index
        settings = Setting.all.order(:key)
        
        render json: {
          data: settings.map do |setting|
            {
              type: 'setting',
              id: setting.id.to_s,
              attributes: {
                key: setting.key,
                value: setting.value,
                description: setting.description,
                value_type: setting.value_type,
                parsed_value: parse_value(setting),
                updated_at: setting.updated_at
              }
            }
          end
        }, status: :ok
      end
      
      # GET /api/admin/settings/:key
      def show
        setting = Setting.find_by!(key: params[:key])
        
        render json: {
          data: {
            type: 'setting',
            id: setting.id.to_s,
            attributes: {
              key: setting.key,
              value: setting.value,
              description: setting.description,
              value_type: setting.value_type,
              parsed_value: parse_value(setting),
              updated_at: setting.updated_at
            }
          }
        }, status: :ok
      end
      
      # PUT /api/admin/settings/:key
      def update
        setting = Setting.find_by!(key: params[:key])
        
        if setting.update(setting_params)
          # Clear cache
          Rails.cache.delete("setting:#{setting.key}")
          
          render json: {
            data: {
              type: 'setting',
              id: setting.id.to_s,
              attributes: {
                key: setting.key,
                value: setting.value,
                description: setting.description,
                value_type: setting.value_type,
                parsed_value: parse_value(setting),
                updated_at: setting.updated_at
              }
            },
            message: 'Ayar güncellendi'
          }, status: :ok
        else
          render json: { 
            error: 'Ayar güncellenemedi', 
            details: setting.errors.full_messages 
          }, status: :unprocessable_entity
        end
      end
      
      private
      
      def ensure_admin
        unless current_user&.admin?
          render json: { error: 'Bu işlem için yetkiniz yok' }, status: :forbidden
        end
      end
      
      def setting_params
        params.require(:setting).permit(:value, :description)
      end
      
      def parse_value(setting)
        Setting.get(setting.key)
      end
    end
  end
end
