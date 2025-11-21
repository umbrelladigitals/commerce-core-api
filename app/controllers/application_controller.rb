class ApplicationController < ActionController::API
  include Pundit::Authorization
  
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from StandardError, with: :handle_internal_server_error
  
  # API için authentication failure durumunda JSON döndür
  def respond_to_unauthenticated_request
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end

  # Override Devise's authenticate_user! to use JWT from Authorization header
  def authenticate_user!
    token = request.headers['Authorization']&.split(' ')&.last
    
    unless token
      return render json: { error: 'No token provided' }, status: :unauthorized
    end
    
    begin
      secret_key = Rails.application.credentials.devise_jwt_secret_key || Rails.application.secret_key_base
      decoded = JWT.decode(token, secret_key, true, { algorithm: 'HS256' })
      payload = decoded.first
      
      @current_user = User.find_by(id: payload['sub'])
      
      unless @current_user
        return render json: { error: 'Invalid token' }, status: :unauthorized
      end
      
    rescue JWT::ExpiredSignature
      render json: { error: 'Token has expired' }, status: :unauthorized
    rescue JWT::DecodeError => e
      render json: { error: 'Invalid token', details: e.message }, status: :unauthorized
    end
  end
  
  # Override current_user to return the authenticated user
  def current_user
    @current_user
  end

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :email, :password, :password_confirmation, :role])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:email, :password])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :email, :password, :password_confirmation, :current_password])
  end

  def user_not_authorized
    render json: { error: 'You are not authorized to perform this action.' }, status: :forbidden
  end

  def handle_internal_server_error(error)
    Rails.logger.error "Internal Server Error: #{error.class} - #{error.message}"
    Rails.logger.error error.backtrace.join("\n") if error.backtrace

    message = 'Beklenmeyen bir hata oluştu'
    message += ": #{error.message}" if Rails.env.development? || Rails.env.test?

    render json: { error: message }, status: :internal_server_error
  end
end
