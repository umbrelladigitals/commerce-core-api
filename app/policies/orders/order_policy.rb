# frozen_string_literal: true

module Orders
  # Order authorization policy
  # Users can only access their own orders
  # Admins can access all orders
  class OrderPolicy < ApplicationPolicy
    def index?
      true # Users can list their own orders
    end

    def show?
      Rails.logger.info "===== ORDER POLICY DEBUG ====="
      Rails.logger.info "User: #{user.inspect}"
      Rails.logger.info "Order ID: #{record.id}, Order user_id: #{record.user_id}"
      Rails.logger.info "User present: #{user.present?}"
      
      return false unless user # Guest users can't view orders without authentication
      
      allowed = user.admin? || record.user_id == user.id
      Rails.logger.info "Authorization result: #{allowed}"
      
      allowed
    end

    def create?
      true # Users can create orders (including guest checkout)
    end

    def update?
      return false unless user
      user.admin? || (record.user_id == user.id && record.cart?)
    end

    def cancel?
      return false unless user
      user.admin? || (record.user_id == user.id && record.can_be_cancelled?)
    end

    def destroy?
      return false unless user
      user.admin?
    end

    class Scope < Scope
      def resolve
        if user.admin?
          scope.all
        else
          scope.where(user_id: user.id)
        end
      end
    end
  end
end
