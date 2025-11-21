# frozen_string_literal: true

module Manufacturing
  class OrderPolicy < ApplicationPolicy
    # Manufacturer rolü gerekli
    def index?
      user&.manufacturer?
    end
    
    def show?
      user&.manufacturer?
    end
    
    def update_status?
      user&.manufacturer?
    end
    
    # Fiyat bilgilerini gizle
    class Scope < Scope
      def resolve
        if user&.manufacturer?
          scope.all
        else
          scope.none
        end
      end
    end
  end
end
