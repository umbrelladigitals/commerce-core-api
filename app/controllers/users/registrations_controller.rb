# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    respond_to :json

    private

    def respond_with(resource, _opts = {})
      if resource.persisted?
        render json: {
          message: 'Signed up successfully.',
          user: resource
        }, status: :created
      else
        render json: {
          message: 'User could not be created.',
          errors: resource.errors.full_messages
        }, status: :unprocessable_entity
      end
    end
  end
end
