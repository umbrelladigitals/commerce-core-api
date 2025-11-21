# frozen_string_literal: true

class ReviewSpamChecker
  RATE_LIMIT_HOURS = 24
  
  def initialize(product_id:, user: nil, guest_email: nil, reviewer_ip: nil)
    @product_id = product_id
    @user = user
    @guest_email = guest_email
    @reviewer_ip = reviewer_ip
  end
  
  def allowed?
    !recent_review_exists?
  end
  
  def error_message
    return nil if allowed?
    
    "You can only submit one review per product every #{RATE_LIMIT_HOURS} hours"
  end
  
  private
  
  def recent_review_exists?
    time_limit = RATE_LIMIT_HOURS.hours.ago
    
    query = Review.where(product_id: @product_id)
                  .where('created_at > ?', time_limit)
    
    # Check by user if authenticated
    if @user.present?
      query = query.where(user_id: @user.id)
      return query.exists?
    end
    
    # Check by IP and guest email for guest reviews
    conditions = []
    conditions << { reviewer_ip: @reviewer_ip } if @reviewer_ip.present?
    conditions << { guest_email: @guest_email } if @guest_email.present?
    
    return false if conditions.empty?
    
    query.where(conditions.reduce(:or)).exists?
  end
end
