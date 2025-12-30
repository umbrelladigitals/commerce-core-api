# frozen_string_literal: true

module Api
  module V1
    module Marketer
      class QuotesController < ApplicationController
        before_action :authenticate_user!
        before_action :require_marketer!
        before_action :set_quote, only: [:show, :update, :destroy, :send_quote, :update_status]

        # GET /api/v1/marketer/quotes
        def index
          @quotes = Quote.where(created_by: current_user).includes(:user, :quote_lines).recent
          
          # Filtreleme
          @quotes = @quotes.where(user_id: params[:user_id]) if params[:user_id].present?
          @quotes = @quotes.where(status: params[:status]) if params[:status].present?
          
          # Sayfalama
          page = params[:page] || 1
          @quotes = @quotes.page(page).per(20)
          
          render json: {
            data: @quotes.map { |quote| serialize_quote(quote) },
            meta: {
              current_page: @quotes.current_page,
              total_pages: @quotes.total_pages,
              total_count: @quotes.total_count
            }
          }
        end

        # GET /api/v1/marketer/quotes/:id
        def show
          render json: {
            data: serialize_quote(@quote, include_lines: true, include_notes: true)
          }
        end

        # POST /api/v1/marketer/quotes
        def create
          user = User.find(params[:user_id])
          
          ActiveRecord::Base.transaction do
            @quote = Quote.create!(
              user: user,
              created_by: current_user,
              status: :draft,
              notes: params[:notes],
              valid_until: params[:valid_until] || 30.days.from_now.to_date,
              currency: params[:currency] || 'USD'
            )
            
            # Teklif satırlarını ekle
            if params[:quote_lines].present?
              params[:quote_lines].each do |line_params|
                product = ::Catalog::Product.find(line_params[:product_id])
                variant = line_params[:variant_id].present? ? ::Catalog::Variant.find(line_params[:variant_id]) : nil
                
                @quote.quote_lines.create!(
                  product: product,
                  variant: variant,
                  quantity: line_params[:quantity] || 1,
                  unit_price_cents: line_params[:unit_price_cents] || (variant&.price_cents || product.price_cents),
                  note: line_params[:note]
                )
              end
              
              # Toplamları hesapla
              @quote.send(:calculate_totals)
            end
            
            # Notify admins
            NotificationService.notify_admins(
              actor: current_user,
              action: 'created_quote',
              notifiable: @quote,
              data: {
                message: "#{current_user.name} yeni bir teklif oluşturdu: ##{@quote.quote_number}",
                link: "/admin/quotes/#{@quote.id}"
              }
            )
            
            render json: {
              message: 'Teklif başarıyla oluşturuldu',
              data: serialize_quote(@quote, include_lines: true)
            }, status: :created
          end
          
        rescue ActiveRecord::RecordNotFound => e
          render json: {
            error: 'Kayıt bulunamadı',
            details: e.message
          }, status: :not_found
        rescue ActiveRecord::RecordInvalid => e
          render json: {
            error: 'Teklif oluşturulamadı',
            details: e.record.errors.full_messages
          }, status: :unprocessable_entity
        end

        # DELETE /api/v1/marketer/quotes/:id
        def destroy
          if @quote.status == 'draft'
            @quote.destroy
            render json: { message: 'Teklif silindi' }
          else
            render json: { error: 'Sadece taslak teklifler silinebilir' }, status: :unprocessable_entity
          end
        end

        # PATCH/PUT /api/v1/marketer/quotes/:id
        def update
          if @quote.status != 'draft'
             return render json: { error: 'Sadece taslak teklifler güncellenebilir' }, status: :unprocessable_entity
          end

          if @quote.update(quote_params)
            render json: {
              message: 'Teklif güncellendi',
              data: serialize_quote(@quote, include_lines: true)
            }
          else
            render json: {
              error: 'Güncelleme başarısız',
              details: @quote.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        # POST /api/v1/marketer/quotes/:id/send
        def send_quote
          if @quote.status == 'draft'
            @quote.update!(status: :sent)
            
            # Notify customer (TODO: Email integration)
            
            render json: {
              message: 'Teklif gönderildi',
              data: serialize_quote(@quote)
            }
          else
            render json: { error: 'Sadece taslak teklifler gönderilebilir' }, status: :unprocessable_entity
          end
        end

        # PATCH /api/v1/marketer/quotes/:id/status
        def update_status
          new_status = params[:status]
          
          unless ['accepted', 'rejected'].include?(new_status)
            return render json: { error: 'Geçersiz durum' }, status: :unprocessable_entity
          end
          
          if @quote.status != 'sent'
            return render json: { error: 'Sadece gönderilmiş tekliflerin durumu değiştirilebilir' }, status: :unprocessable_entity
          end
          
          if @quote.update(status: new_status)
            render json: {
              message: "Teklif #{new_status == 'accepted' ? 'kabul edildi' : 'reddedildi'}",
              data: serialize_quote(@quote)
            }
          else
            render json: {
              error: 'Durum güncellenemedi',
              details: @quote.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        private

        def quote_params
          params.permit(:notes, :valid_until, :currency)
        end

        def require_marketer!
          unless current_user&.role == 'marketer'
            render json: {
              status: 'error',
              message: 'Bu işlem için yetkiniz yok'
            }, status: :forbidden
          end
        end

        def set_quote
          @quote = Quote.where(created_by: current_user).find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'Teklif bulunamadı' }, status: :not_found
        end

        def serialize_quote(quote, include_lines: false, include_notes: false)
          data = {
            id: quote.id,
            quote_number: quote.quote_number,
            status: quote.status,
            total: quote.total.format,
            currency: quote.currency,
            valid_until: quote.valid_until,
            created_at: quote.created_at,
            user: {
              id: quote.user.id,
              name: quote.user.name,
              email: quote.user.email
            },
            created_by: {
              id: quote.created_by.id,
              name: quote.created_by.name
            }
          }
          
          if include_lines
            data[:lines] = quote.quote_lines.includes(:product, :variant).map do |line|
              {
                id: line.id,
                product_name: line.product.title,
                variant_name: line.variant&.display_name,
                quantity: line.quantity,
                unit_price: line.unit_price.format,
                total_price: line.total.format,
                note: line.note
              }
            end
          end
          
          if include_notes
            data[:notes] = quote.notes
          end
          
          data
        end
      end
    end
  end
end
