# frozen_string_literal: true

module Api
  module V1
    module Users
      class ProfilesController < Api::V1::BaseController
        before_action :authenticate_user!

        def show
          render json: current_user, status: :ok
        end

        def update
          if current_user.update(user_params)
            render json: { user: current_user }, status: :ok
          else
            render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def change_password
          unless current_user.valid_password?(params[:current_password])
            render json: { message: 'Mevcut şifre yanlış' }, status: :unprocessable_entity
            return
          end

          if current_user.update(
            password: params[:password],
            password_confirmation: params[:password_confirmation]
          )
            render json: { message: 'Şifre başarıyla değiştirildi' }, status: :ok
          else
            render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update_notification_settings
          settings = params[:notification_settings] || {}
          
          # User modeline notification fields eklenebilir veya ayrı bir tablo kullanılabilir
          # Şimdilik basit bir implementasyon yapıyoruz
          if current_user.update(
            email_notifications: settings[:email_notifications],
            sms_notifications: settings[:sms_notifications],
            whatsapp_notifications: settings[:whatsapp_notifications]
          )
            render json: { message: 'Bildirim ayarları güncellendi' }, status: :ok
          else
            render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        private

        def user_params
          params.require(:user).permit(:name, :email, :phone, :address, :city, :company)
        end
      end
    end
  end
end
