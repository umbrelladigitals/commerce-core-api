# frozen_string_literal: true

module Api
  module V1
    # Teklif/Proforma yönetimi
    # Sadece admin kullanıcılar teklif oluşturabilir
    class QuotesController < Api::V1::BaseController
      before_action :authenticate_user!
      before_action :authorize_admin!, except: [:index, :show, :accept, :reject]
      before_action :set_quote, only: [:show, :update, :destroy, :send_quote, :accept, :reject]
      before_action :authorize_quote_owner!, only: [:accept, :reject]
      
      # GET /api/v1/quotes
      def index
        if current_user.admin?
          # Admin tüm teklifleri görebilir
          @quotes = Quote.recent.includes(:user, :created_by, :quote_lines)
        else
          # Kullanıcı sadece kendi tekliflerini görebilir
          @quotes = current_user.quotes.recent.includes(:created_by, :quote_lines)
        end
        
        # Filtreleme
        @quotes = @quotes.where(status: params[:status]) if params[:status].present?
        @quotes = @quotes.where(user_id: params[:user_id]) if params[:user_id].present? && current_user.admin?
        
        render json: {
          data: @quotes.map { |quote| serialize_quote(quote) }
        }
      end
      
      # GET /api/v1/quotes/:id
      def show
        render json: {
          data: serialize_quote(@quote, include_lines: true)
        }
      end
      
      # POST /api/v1/quotes
      # Admin creates quote for a user
      def create
        @quote = Quote.new(quote_params)
        @quote.created_by = current_user
        @quote.currency ||= 'USD'
        
        if @quote.save
          # Satırları ekle
          if params[:quote_lines].present?
            params[:quote_lines].each do |line_params|
              @quote.quote_lines.create!(
                product_id: line_params[:product_id],
                variant_id: line_params[:variant_id],
                quantity: line_params[:quantity],
                note: line_params[:note]
              )
            end
          end
          
          render json: {
            message: 'Teklif oluşturuldu',
            data: serialize_quote(@quote.reload, include_lines: true)
          }, status: :created
        else
          render json: {
            error: 'Teklif oluşturulamadı',
            details: @quote.errors.full_messages
          }, status: :unprocessable_entity
        end
      end
      
      # PATCH /api/v1/quotes/:id
      def update
        if @quote.update(quote_params)
          # Satırları güncelle
          if params[:quote_lines].present?
            @quote.quote_lines.destroy_all
            params[:quote_lines].each do |line_params|
              @quote.quote_lines.create!(
                product_id: line_params[:product_id],
                variant_id: line_params[:variant_id],
                quantity: line_params[:quantity],
                note: line_params[:note]
              )
            end
          end
          
          render json: {
            message: 'Teklif güncellendi',
            data: serialize_quote(@quote.reload, include_lines: true)
          }
        else
          render json: {
            error: 'Teklif güncellenemedi',
            details: @quote.errors.full_messages
          }, status: :unprocessable_entity
        end
      end
      
      # DELETE /api/v1/quotes/:id
      def destroy
        @quote.destroy
        render json: { message: 'Teklif silindi' }
      end
      
      # POST /api/v1/quotes/:id/send
      # Teklifi müşteriye gönder
      def send_quote
        if @quote.draft?
          @quote.update!(status: :sent)
          
          # TODO: Email gönder
          # QuoteMailer.send_quote(@quote).deliver_later
          
          render json: {
            message: 'Teklif gönderildi',
            data: serialize_quote(@quote)
          }
        else
          render json: {
            error: 'Sadece taslak teklifler gönderilebilir'
          }, status: :unprocessable_entity
        end
      end
      
      # POST /api/v1/quotes/:id/accept
      # Müşteri teklifi kabul eder ve siparişe dönüştürür
      def accept
        unless @quote.sent?
          return render json: {
            error: 'Sadece gönderilmiş teklifler kabul edilebilir'
          }, status: :unprocessable_entity
        end
        
        if @quote.expired?
          return render json: {
            error: 'Teklifin süresi dolmuş'
          }, status: :unprocessable_entity
        end
        
        order = @quote.convert_to_order!
        
        if order
          render json: {
            message: 'Teklif kabul edildi ve siparişe dönüştürüldü',
            data: {
              quote: serialize_quote(@quote),
              order: {
                id: order.id,
                order_number: order.order_number,
                status: order.status,
                total: order.total.format
              }
            }
          }
        else
          render json: {
            error: 'Teklif siparişe dönüştürülemedi'
          }, status: :unprocessable_entity
        end
      end
      
      # POST /api/v1/quotes/:id/reject
      # Müşteri teklifi reddeder
      def reject
        if @quote.sent?
          @quote.update!(status: :rejected)
          
          render json: {
            message: 'Teklif reddedildi',
            data: serialize_quote(@quote)
          }
        else
          render json: {
            error: 'Sadece gönderilmiş teklifler reddedilebilir'
          }, status: :unprocessable_entity
        end
      end
      
      private
      
      def set_quote
        @quote = Quote.find(params[:id])
      end
      
      def authorize_admin!
        unless current_user&.admin?
          render json: { error: 'Yetkisiz erişim' }, status: :forbidden
        end
      end
      
      def authorize_quote_owner!
        unless current_user.admin? || @quote.user_id == current_user.id
          render json: { error: 'Bu teklifi görüntüleme yetkiniz yok' }, status: :forbidden
        end
      end
      
      def quote_params
        params.require(:quote).permit(
          :user_id,
          :valid_until,
          :notes,
          :status
        )
      end
      
      def serialize_quote(quote, include_lines: false)
        data = {
          type: 'quote',
          id: quote.id.to_s,
          attributes: {
            quote_number: quote.quote_number,
            user_id: quote.user_id,
            user_name: quote.user.name || quote.user.email,
            created_by_id: quote.created_by_id,
            created_by_name: quote.created_by.name || quote.created_by.email,
            status: quote.status,
            valid_until: quote.valid_until,
            expired: quote.expired?,
            active: quote.active?,
            subtotal: quote.subtotal.format,
            shipping: quote.shipping.format,
            tax: quote.tax.format,
            total: quote.total.format,
            currency: quote.currency,
            notes: quote.notes,
            total_items: quote.total_items,
            created_at: quote.created_at,
            updated_at: quote.updated_at
          }
        }
        
        if include_lines
          data[:included] = quote.quote_lines.map do |line|
            {
              type: 'quote_line',
              id: line.id.to_s,
              attributes: {
                product_id: line.product_id,
                product_title: line.product_title,
                variant_id: line.variant_id,
                variant_name: line.variant_name,
                quantity: line.quantity,
                unit_price: line.unit_price.format,
                total: line.total.format,
                note: line.note
              }
            }
          end
        end
        
        data
      end
    end
  end
end
