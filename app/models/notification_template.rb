class NotificationTemplate < ApplicationRecord
  CHANNELS = %w[email sms whatsapp].freeze
  
  # Validations
  validates :name, presence: true
  validates :channel, presence: true, inclusion: { in: CHANNELS }
  validates :body, presence: true
  validates :subject, presence: true, if: -> { channel == 'email' }
  validates :name, uniqueness: { scope: :channel }
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_channel, ->(channel) { where(channel: channel) }
  
  # Associations
  has_many :notification_logs, dependent: :destroy
  
  # Template placeholder replacement
  def render_body(variables = {})
    rendered = body.dup
    variables.each do |key, value|
      rendered.gsub!("{{#{key}}}", value.to_s)
    end
    rendered
  end
  
  def render_subject(variables = {})
    return nil unless subject.present?
    
    rendered = subject.dup
    variables.each do |key, value|
      rendered.gsub!("{{#{key}}}", value.to_s)
    end
    rendered
  end
  
  # Check if email channel
  def email?
    channel == 'email'
  end
  
  def sms?
    channel == 'sms'
  end
  
  def whatsapp?
    channel == 'whatsapp'
  end
end
