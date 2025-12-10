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
      return false unless user # Guest users can't view orders without authentication
      
      user.admin? || 
      record.user_id == user.id || 
      (user.marketer? && record.created_by_marketer_id == user.id)
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
        elsif user.marketer?
          scope.where('user_id = ? OR created_by_marketer_id = ?', user.id, user.id)
        else
          scope.where(user_id: user.id)
        end
      end
    end
  end
end
