# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    respond_to :json

    private

    def respond_with(resource, _opts = {})
      # Generate JWT token
      token = resource.generate_jwt
      
      render json: {
        message: 'Logged in successfully.',
        token: token,
        user: {
          id: resource.id,
          email: resource.email,
          name: resource.name,
          role: resource.role,
          created_at: resource.created_at,
          updated_at: resource.updated_at
        }
      }, status: :ok
    end

    def respond_to_on_destroy
      if current_user
        render json: {
          message: 'Logged out successfully.'
        }, status: :ok
      else
        render json: {
          message: 'No active session.'
        }, status: :unauthorized
      end
    end
  end
end
