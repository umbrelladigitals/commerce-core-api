# frozen_string_literal: true

module Api
  module V1
    module Admin
      class NotificationTemplatesController < Api::V1::BaseController
        before_action :authenticate_user!
        before_action :authorize_admin!
        before_action :set_template, only: [:show, :update, :destroy]
        
        # GET /api/v1/admin/notification_templates
        def index
          templates = NotificationTemplate.all.order(created_at: :desc)
          
          render json: {
            data: templates.map { |t| serialize_template(t) }
          }, status: :ok
        end
        
        # GET /api/v1/admin/notification_templates/:id
        def show
          render json: {
            data: serialize_template(@template)
          }, status: :ok
        end
        
        # POST /api/v1/admin/notification_templates
        def create
          template = NotificationTemplate.new(template_params)
          
          if template.save
            render json: {
              data: serialize_template(template)
            }, status: :created
          else
            render json: {
              errors: template.errors.full_messages
            }, status: :unprocessable_entity
          end
        end
        
        # PATCH /api/v1/admin/notification_templates/:id
        def update
          if @template.update(template_params)
            render json: {
              data: serialize_template(@template)
            }, status: :ok
          else
            render json: {
              errors: @template.errors.full_messages
            }, status: :unprocessable_entity
          end
        end
        
        # DELETE /api/v1/admin/notification_templates/:id
        def destroy
          @template.destroy
          head :no_content
        end
        
        private
        
        def set_template
          @template = NotificationTemplate.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Template not found' }, status: :not_found
        end
        
        def template_params
          params.require(:notification_template).permit(
            :name,
            :channel,
            :subject,
            :body,
            :active
          )
        end
        
        def authorize_admin!
          unless current_user&.admin?
            render json: { error: 'Forbidden' }, status: :forbidden
          end
        end
        
        def serialize_template(template)
          {
            id: template.id,
            name: template.name,
            channel: template.channel,
            subject: template.subject,
            body: template.body,
            active: template.active,
            created_at: template.created_at,
            updated_at: template.updated_at
          }
        end
      end
    end
  end
end
