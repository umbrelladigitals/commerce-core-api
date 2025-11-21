# frozen_string_literal: true

module Api
  module V1
    class ReviewsController < ApplicationController
      before_action :set_product, only: [:create]
      # skip_before_action :authenticate_user!, only: [:create]
      
      # POST /api/v1/products/:product_id/reviews
      def create
        spam_checker = ReviewSpamChecker.new(
          product_id: @product.id,
          user: current_user,
          guest_email: review_params[:guest_email],
          reviewer_ip: request.remote_ip
        )
        
        unless spam_checker.allowed?
          return render json: { error: spam_checker.error_message }, status: :too_many_requests
        end
        
        @review = @product.reviews.build(review_params)
        @review.user = current_user if user_signed_in?
        @review.reviewer_ip = request.remote_ip
        
        if @review.save
          render json: {
            message: 'Review submitted successfully. It will be visible after approval.',
            data: serialize_review(@review)
          }, status: :created
        else
          render json: { errors: @review.errors.full_messages }, status: :unprocessable_entity
        end
      end
      
      private
      
      def set_product
        @product = Catalog::Product.find(params[:product_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Product not found' }, status: :not_found
      end
      
      def review_params
        params.require(:review).permit(:rating, :comment, :guest_email)
      end
      
      def serialize_review(review)
        {
          id: review.id,
          rating: review.rating,
          comment: review.comment,
          reviewer_name: review.reviewer_name,
          approved: review.approved,
          created_at: review.created_at
        }
      end
    end
  end
end
