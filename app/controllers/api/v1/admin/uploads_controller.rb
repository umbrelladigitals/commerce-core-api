module Api
  module V1
    module Admin
      class UploadsController < ApplicationController
        before_action :authenticate_user!
        before_action :require_admin!

        def create
          if params[:file].present?
            blob = ActiveStorage::Blob.create_and_upload!(
              io: params[:file],
              filename: params[:file].original_filename,
              content_type: params[:file].content_type
            )
            
            render json: { 
              url: blob.url,
              signed_id: blob.signed_id,
              filename: blob.filename.to_s,
              content_type: blob.content_type
            }, status: :created
          else
            render json: { error: 'Dosya yüklenemedi' }, status: :unprocessable_entity
          end
        end

        private

        def require_admin!
          unless current_user.admin?
            render json: { error: 'Yetkisiz erişim' }, status: :forbidden
          end
        end
      end
    end
  end
end
