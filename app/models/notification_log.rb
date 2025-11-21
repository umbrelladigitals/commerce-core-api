class NotificationLog < ApplicationRecord
  STATUSES = %w[pending sent failed delivered].freeze
  CHANNELS = %w[email sms whatsapp].freeze
  
  # Associations
  belongs_to :notification_template, optional: true
  belongs_to :user, optional: true
  
  # Validations
  validates :recipient, presence: true
  validates :channel, presence: true, inclusion: { in: CHANNELS }
  validates :status, presence: true, inclusion: { in: STATUSES }
  
  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :sent, -> { where(status: 'sent') }
  scope :failed, -> { where(status: 'failed') }
  scope :delivered, -> { where(status: 'delivered') }
  scope :by_channel, ->(channel) { where(channel: channel) }
  scope :recent, -> { order(created_at: :desc) }
  
  # Status transitions
  def mark_as_sent!
    update!(status: 'sent', sent_at: Time.current)
  end
  
  def mark_as_failed!(error)
    update!(status: 'failed', error_message: error)
  end
  
  def mark_as_delivered!
    update!(status: 'delivered')
  end
end
