# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      # API responses için JSON döndür, redirect etme
      respond_to :json
      
      # 401 Unauthorized yerine redirect etme
      def respond_to_unauthenticated
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
    end
  end
end
