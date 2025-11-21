# frozen_string_literal: true

module Api
  module V1
    module Admin
      class NotificationsController < Api::V1::BaseController
        before_action :authenticate_user!
        before_action :authorize_admin!
        
        # POST /api/v1/admin/notifications/send
        # Toplu bildirim gönderimi
        def send_bulk
          template_id = params.require(:template_id)
          targets = params.require(:targets)
          
          template = NotificationTemplate.find(template_id)
          
          unless template.active?
            return render json: {
              error: 'Template is not active'
            }, status: :unprocessable_entity
          end
          
          recipients = resolve_recipients(targets)
          
          if recipients.empty?
            return render json: {
              error: 'No recipients found'
            }, status: :unprocessable_entity
          end
          
          # Send notifications
          results = {
            total: recipients.length,
            sent: 0,
            failed: 0,
            logs: []
          }
          
          recipients.each do |recipient_data|
            result = NotificationSender.new(
              template: template,
              recipient: recipient_data[:contact],
              variables: recipient_data[:variables] || {},
              user: recipient_data[:user]
            ).send!
            
            if result[:success]
              results[:sent] += 1
            else
              results[:failed] += 1
            end
            
            results[:logs] << {
              recipient: recipient_data[:contact],
              status: result[:success] ? 'sent' : 'failed',
              error: result[:error],
              log_id: result[:log]&.id
            }
          end
          
          render json: {
            data: results
          }, status: :ok
        end
        
        # GET /api/v1/admin/notifications/logs
        def logs
          logs = NotificationLog
                   .includes(:notification_template, :user)
                   .order(created_at: :desc)
                   .limit(params[:limit] || 100)
          
          if params[:status].present?
            logs = logs.where(status: params[:status])
          end
          
          if params[:channel].present?
            logs = logs.where(channel: params[:channel])
          end
          
          render json: {
            data: logs.map { |log| serialize_log(log) }
          }, status: :ok
        end
        
        # GET /api/v1/admin/notifications/logs/:id
        def show_log
          log = NotificationLog.find(params[:id])
          
          render json: {
            data: serialize_log(log)
          }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Log not found' }, status: :not_found
        end
        
        private
        
        def authorize_admin!
          unless current_user&.admin?
            render json: { error: 'Forbidden' }, status: :forbidden
          end
        end
        
        def resolve_recipients(targets)
          recipients = []
          
          # Dealer IDs
          if targets[:dealer_ids].present?
            dealers = User.where(role: :dealer, id: targets[:dealer_ids])
            dealers.each do |dealer|
              recipients << {
                user: dealer,
                contact: dealer.email,
                variables: {
                  customer_name: dealer.name,
                  customer_email: dealer.email
                }
              }
            end
          end
          
          # Customer IDs
          if targets[:customer_ids].present?
            customers = User.where(role: :customer, id: targets[:customer_ids])
            customers.each do |customer|
              recipients << {
                user: customer,
                contact: customer.email,
                variables: {
                  customer_name: customer.name,
                  customer_email: customer.email
                }
              }
            end
          end
          
          # Direct emails
          if targets[:emails].present?
            targets[:emails].each do |email|
              recipients << {
                user: nil,
                contact: email,
                variables: {
                  customer_email: email
                }
              }
            end
          end
          
          recipients
        end
        
        def serialize_log(log)
          {
            id: log.id,
            recipient: log.recipient,
            channel: log.channel,
            status: log.status,
            error_message: log.error_message,
            sent_at: log.sent_at,
            payload: log.payload,
            template: log.notification_template ? {
              id: log.notification_template.id,
              name: log.notification_template.name
            } : nil,
            user: log.user ? {
              id: log.user.id,
              name: log.user.name,
              email: log.user.email
            } : nil,
            created_at: log.created_at
          }
        end
      end
    end
  end
end
