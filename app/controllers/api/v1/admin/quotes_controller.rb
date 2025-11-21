# frozen_string_literal: true

module Api
  module V1
    module Admin
      # Teklif/Proforma yönetimi
      # Yöneticiler müşteri/bayi adına teklif oluşturabilir
      class QuotesController < ApplicationController
        before_action :authenticate_user!
        before_action :require_admin!
        before_action :set_quote, only: [:show, :update, :destroy, :convert_to_order, :send_quote]
        
        # GET /api/v1/admin/quotes
        def index
          @quotes = Quote.includes(:user, :created_by, :quote_lines).recent
          
          # Filtreleme
          @quotes = @quotes.where(user_id: params[:user_id]) if params[:user_id].present?
          @quotes = @quotes.where(status: params[:status]) if params[:status].present?
          @quotes = @quotes.created_by(params[:created_by_id]) if params[:created_by_id].present?
          
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
        
        # GET /api/v1/admin/quotes/:id
        def show
          render json: {
            data: serialize_quote(@quote, include_lines: true, include_notes: true)
          }
        end
        
        # POST /api/v1/admin/quotes
        def create
          user = User.find(params[:user_id])
          
          ActiveRecord::Base.transaction do
            @quote = Quote.create!(
              user: user,
              created_by: current_user,
              status: params[:status] || :draft,
              notes: params[:notes],
              valid_until: params[:valid_until] || 30.days.from_now.to_date,
              currency: params[:currency] || 'USD'
            )
            
            # Teklif satırlarını ekle
            if params[:quote_lines].present?
              params[:quote_lines].each do |line_params|
                product = Catalog::Product.find(line_params[:product_id])
                variant = line_params[:variant_id].present? ? Catalog::Variant.find(line_params[:variant_id]) : nil
                
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
            
            # Admin notu ekle
            if params[:admin_note].present?
              @quote.admin_notes.create!(
                note: params[:admin_note],
                author: current_user
              )
            end
            
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
        
        # PATCH /api/v1/admin/quotes/:id
        def update
          if @quote.update(quote_update_params)
            # Durum değişikliği için not ekle
            if params[:admin_note].present?
              @quote.admin_notes.create!(
                note: params[:admin_note],
                author: current_user
              )
            end
            
            render json: {
              message: 'Teklif güncellendi',
              data: serialize_quote(@quote, include_lines: true)
            }
          else
            render json: {
              error: 'Teklif güncellenemedi',
              details: @quote.errors.full_messages
            }, status: :unprocessable_entity
          end
        end
        
        # DELETE /api/v1/admin/quotes/:id
        def destroy
          unless @quote.draft?
            return render json: {
              error: 'Sadece taslak teklifler silinebilir'
            }, status: :unprocessable_entity
          end
          
          @quote.destroy
          render json: { message: 'Teklif silindi' }
        end
        
        # POST /api/v1/admin/quotes/:id/convert
        # Teklifi siparişe dönüştür
        def convert_to_order
          unless @quote.sent?
            return render json: {
              error: 'Sadece gönderilmiş teklifler siparişe dönüştürülebilir'
            }, status: :unprocessable_entity
          end
          
          if @quote.expired?
            return render json: {
              error: 'Teklif süresi dolmuş'
            }, status: :unprocessable_entity
          end
          
          order = @quote.convert_to_order!
          
          if order
            render json: {
              message: 'Teklif siparişe dönüştürüldü',
              data: {
                quote_id: @quote.id,
                order_id: order.id,
                order_number: order.order_number
              }
            }
          else
            render json: {
              error: 'Teklif siparişe dönüştürülemedi'
            }, status: :unprocessable_entity
          end
        end
        
        # POST /api/v1/admin/quotes/:id/send
        # Teklifi müşteriye gönder (durumunu sent yap)
        def send_quote
          unless @quote.draft?
            return render json: {
              error: 'Sadece taslak teklifler gönderilebilir'
            }, status: :unprocessable_entity
          end
          
          if @quote.update(status: :sent)
            @quote.admin_notes.create!(
              note: "Teklif müşteriye gönderildi",
              author: current_user
            )
            
            # TODO: Email gönderimi burada yapılabilir
            # QuoteMailer.send_quote(@quote).deliver_later
            
            render json: {
              message: 'Teklif gönderildi',
              data: serialize_quote(@quote)
            }
          else
            render json: {
              error: 'Teklif gönderilemedi',
              details: @quote.errors.full_messages
            }, status: :unprocessable_entity
          end
        end
        
        private
        
        def set_quote
          @quote = Quote.includes(:user, :created_by, :quote_lines, :admin_notes).find(params[:id])
        end
        
        def quote_update_params
          params.require(:quote).permit(:status, :notes, :valid_until)
        end
        
        def serialize_quote(quote, include_lines: false, include_notes: false)
          data = {
            type: 'quotes',
            id: quote.id.to_s,
            attributes: {
              quote_number: quote.quote_number,
              status: quote.status,
              valid_until: quote.valid_until,
              expired: quote.expired?,
              active: quote.active?,
              notes: quote.notes,
              total: quote.total.format,
              subtotal: quote.subtotal.format,
              tax: quote.tax.format,
              shipping: quote.shipping.format,
              currency: quote.currency,
              items_count: quote.quote_lines.count,
              total_quantity: quote.total_items,
              created_at: quote.created_at,
              updated_at: quote.updated_at
            },
            relationships: {
              user: {
                data: { type: 'users', id: quote.user_id.to_s }
              },
              created_by: {
                data: { type: 'users', id: quote.created_by_id.to_s }
              }
            },
            included: {
              user: {
                id: quote.user.id,
                name: quote.user.name,
                email: quote.user.email,
                role: quote.user.role
              },
              created_by: {
                id: quote.created_by.id,
                name: quote.created_by.name,
                email: quote.created_by.email
              }
            }
          }
          
          if include_lines
            data[:included][:quote_lines] = quote.quote_lines.map do |line|
              {
                id: line.id,
                product_id: line.product_id,
                product_title: line.product_title,
                variant_id: line.variant_id,
                variant_name: line.variant_name,
                quantity: line.quantity,
                unit_price: line.unit_price.format,
                total: line.total.format,
                note: line.note
              }
            end
          end
          
          if include_notes
            data[:included][:admin_notes] = quote.admin_notes.recent.map do |note|
              {
                id: note.id,
                note: note.note,
                author_name: note.author.name,
                created_at: note.created_at
              }
            end
          end
          
          data
        end
        
        def require_admin!
          unless current_user.admin?
            render json: { error: 'Yetkisiz erişim' }, status: :forbidden
          end
        end
      end
    end
  end
end
