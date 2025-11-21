# frozen_string_literal: true

module Api
  module V1
    module Admin
      class ReviewsController < ApplicationController
        before_action :authenticate_user!
        before_action :authorize_admin!
        before_action :set_review, only: [:show, :approve, :reject, :destroy]
        
        # GET /api/v1/admin/reviews
        def index
          @reviews = Review.includes(:product, :user)
                          .recent
          
          # Filters
          @reviews = @reviews.where(approved: params[:approved]) if params[:approved].present?
          @reviews = @reviews.by_product(params[:product_id]) if params[:product_id].present?
          @reviews = @reviews.by_rating(params[:rating]) if params[:rating].present?
          
          # Pagination
          page = params[:page] || 1
          per_page = params[:per_page] || 20
          
          @pagy, @reviews = pagy(@reviews, page: page, items: per_page)
          
          render json: {
            data: @reviews.map { |r| serialize_review(r) },
            meta: pagy_metadata(@pagy)
          }
        end
        
        # GET /api/v1/admin/reviews/:id
        def show
          render json: { data: serialize_review(@review, detailed: true) }
        end
        
        # PATCH /api/v1/admin/reviews/:id/approve
        def approve
          @review.approve!
          render json: {
            message: 'Review approved successfully',
            data: serialize_review(@review)
          }
        end
        
        # PATCH /api/v1/admin/reviews/:id/reject
        def reject
          @review.reject!
          render json: {
            message: 'Review rejected successfully',
            data: serialize_review(@review)
          }
        end
        
        # DELETE /api/v1/admin/reviews/:id
        def destroy
          @review.destroy
          render json: { message: 'Review deleted successfully' }
        end
        
        private
        
        def set_review
          @review = Review.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Review not found' }, status: :not_found
        end
        
        def authorize_admin!
          unless current_user&.admin?
            render json: { error: 'Unauthorized' }, status: :forbidden
          end
        end
        
        def serialize_review(review, detailed: false)
          base = {
            id: review.id,
            product_id: review.product_id,
            product_title: review.product.title,
            rating: review.rating,
            comment: review.comment,
            reviewer_name: review.reviewer_name,
            approved: review.approved,
            created_at: review.created_at
          }
          
          if detailed
            base.merge!(
              user_id: review.user_id,
              user_email: review.user&.email,
              guest_email: review.guest_email,
              reviewer_ip: review.reviewer_ip,
              updated_at: review.updated_at
            )
          end
          
          base
        end
      end
    end
  end
end
