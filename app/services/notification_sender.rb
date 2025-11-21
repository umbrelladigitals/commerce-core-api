# frozen_string_literal: true

class NotificationSender
  attr_reader :template, :recipient, :variables, :user
  
  def initialize(template:, recipient:, variables: {}, user: nil)
    @template = template
    @recipient = recipient
    @variables = variables
    @user = user
  end
  
  def send!
    # Create log entry
    log = NotificationLog.create!(
      notification_template: template,
      user: user,
      recipient: recipient,
      channel: template.channel,
      payload: {
        template_name: template.name,
        variables: variables,
        rendered_body: template.render_body(variables),
        rendered_subject: template.render_subject(variables)
      },
      status: 'pending'
    )
    
    begin
      case template.channel
      when 'email'
        send_email(log)
      when 'sms'
        send_sms(log)
      when 'whatsapp'
        send_whatsapp(log)
      else
        raise "Unknown channel: #{template.channel}"
      end
      
      log.mark_as_sent!
      { success: true, log: log }
    rescue StandardError => e
      log.mark_as_failed!(e.message)
      { success: false, error: e.message, log: log }
    end
  end
  
  private
  
  def send_email(log)
    NotificationMailer.send_notification(
      to: recipient,
      subject: log.payload['rendered_subject'],
      body: log.payload['rendered_body']
    ).deliver_now
    
    Rails.logger.info("Email sent to #{recipient}")
  end
  
  def send_sms(log)
    # Placeholder for SMS service (Twilio, etc.)
    # In production, integrate with actual SMS provider
    
    Rails.logger.info("SMS would be sent to #{recipient}: #{log.payload['rendered_body']}")
    
    # Example Twilio integration (commented out):
    # client = Twilio::REST::Client.new(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
    # client.messages.create(
    #   from: ENV['TWILIO_PHONE_NUMBER'],
    #   to: recipient,
    #   body: log.payload['rendered_body']
    # )
  end
  
  def send_whatsapp(log)
    # Generate WhatsApp deep link
    # wa.me format: https://wa.me/<phone>?text=<message>
    
    message = URI.encode_www_form_component(log.payload['rendered_body'])
    phone = recipient.gsub(/\D/, '') # Remove non-digits
    whatsapp_url = "https://wa.me/#{phone}?text=#{message}"
    
    # Store the deep link in payload
    log.update!(
      payload: log.payload.merge(whatsapp_url: whatsapp_url)
    )
    
    Rails.logger.info("WhatsApp deep link generated for #{recipient}: #{whatsapp_url}")
    
    # Note: WhatsApp deep links need to be opened by user
    # In a real app, you might send this link via email or display it in admin panel
  end
end
