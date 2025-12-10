module Api
  module V1
    module Users
      class AddressesController < Api::V1::BaseController
        before_action :authenticate_user!
        before_action :set_address, only: [:show, :update, :destroy]

        def index
          render json: current_user.addresses
        end

        def show
          render json: @address
        end

        def create
          @address = current_user.addresses.build(address_params)

          if @address.save
            render json: @address, status: :created
          else
            render json: { errors: @address.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def update
          if @address.update(address_params)
            render json: @address
          else
            render json: { errors: @address.errors.full_messages }, status: :unprocessable_entity
          end
        end

        def destroy
          @address.destroy
          head :no_content
        end

        private

        def set_address
          @address = current_user.addresses.find(params[:id])
        end

        def address_params
          params.require(:address).permit(:title, :name, :phone, :address_line1, :address_line2, :city, :state, :postal_code, :country, :address_type)
        end
      end
    end
  end
end
