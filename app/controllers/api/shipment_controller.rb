# frozen_string_literal: true

module Api
  # Kargo takip API controller'ı
  # Kargo gönderimi oluşturma ve takip işlemleri
  class ShipmentController < ApplicationController
    before_action :authenticate_user!
    before_action :set_shipment, only: [:show, :update_status, :track, :cancel]
    before_action :require_admin_for_create!, only: [:create]
    before_action :require_admin_or_owner!, only: [:show, :track]
    
    # GET /api/shipment
    # Kullanıcının kargo listesi
    def index
      if current_user.admin?
        @shipments = Shipment.includes(:order).recent
      else
        order_ids = current_user.orders.pluck(:id)
        @shipments = Shipment.where(order_id: order_ids).includes(:order).recent
      end
      
      # Filtreleme
      @shipments = @shipments.by_carrier(params[:carrier]) if params[:carrier].present?
      @shipments = @shipments.by_status(params[:status]) if params[:status].present?
      
      # Sayfalama
      page = params[:page] || 1
      @shipments = @shipments.page(page).per(20)
      
      render json: {
        data: @shipments.map { |shipment| serialize_shipment(shipment) },
        meta: {
          current_page: @shipments.current_page,
          total_pages: @shipments.total_pages,
          total_count: @shipments.total_count
        }
      }
    end
    
    # GET /api/shipment/:id
    # Kargo detayı
    def show
      render json: {
        data: serialize_shipment(@shipment, include_order: true)
      }
    end
    
    # POST /api/shipment/create
    # Yeni kargo oluştur (Admin only)
    def create
  order = ::Orders::Order.find(params[:order_id])
      
      # Sipariş zaten gönderilmiş mi?
      if order.shipment.present?
        return render json: {
          error: 'Bu sipariş için zaten kargo kaydı mevcut',
          existing_tracking_number: order.shipment.tracking_number
        }, status: :unprocessable_entity
      end
      
      # Sipariş paid durumunda olmalı
      unless order.paid?
        return render json: {
          error: 'Sadece ödenmiş siparişler için kargo oluşturulabilir'
        }, status: :unprocessable_entity
      end
      
      # Kargo firması destekleniyor mu?
      carrier = params[:carrier]&.to_sym
      unless Cargo::ServiceFactory.supported?(carrier)
        return render json: {
          error: 'Desteklenmeyen kargo firması',
          available_carriers: Cargo::ServiceFactory.available_carriers
        }, status: :unprocessable_entity
      end
      
      # Geçici shipment oluştur
      @shipment = Shipment.new(
        order: order,
        carrier: carrier.to_s,
        status: :preparing,
        notes: params[:notes]
      )
      
      # Kargo servisini başlat
      cargo_service = Cargo::ServiceFactory.create(carrier, @shipment)
      result = cargo_service.create_shipment
      
      if result[:success]
        @shipment.tracking_number = result[:tracking_number]
        @shipment.estimated_delivery = result[:estimated_delivery]
        
        if @shipment.save
          # Admin notu ekle
          @shipment.admin_notes.create!(
            note: "Kargo oluşturuldu - #{result[:message]}",
            author: current_user
          )
          
          render json: {
            message: 'Kargo başarıyla oluşturuldu',
            data: serialize_shipment(@shipment, include_order: true),
            tracking_url: @shipment.tracking_url
          }, status: :created
        else
          render json: {
            error: 'Kargo kaydı oluşturulamadı',
            details: @shipment.errors.full_messages
          }, status: :unprocessable_entity
        end
      else
        render json: {
          error: 'Kargo oluşturulamadı',
          details: result[:error]
        }, status: :unprocessable_entity
      end
      
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Sipariş bulunamadı' }, status: :not_found
    rescue StandardError => e
      Rails.logger.error "Kargo oluşturma hatası: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: {
        error: 'Beklenmeyen bir hata oluştu',
        details: e.message
      }, status: :internal_server_error
    end
    
    # PATCH /api/shipment/:id/update_status
    # Kargo durumunu güncelle (Admin only)
    def update_status
      unless current_user.admin?
        return render json: { error: 'Yetkisiz erişim' }, status: :forbidden
      end
      
      new_status = params[:status]
      
      unless Shipment.statuses.key?(new_status)
        return render json: {
          error: 'Geçersiz durum',
          available_statuses: Shipment.statuses.keys
        }, status: :unprocessable_entity
      end
      
      if @shipment.update(
        status: new_status,
        notes: params[:notes] || @shipment.notes
      )
        # Admin notu ekle
        @shipment.admin_notes.create!(
          note: "Durum güncellendi: #{new_status} - #{params[:admin_note]}",
          author: current_user
        ) if params[:admin_note].present?
        
        render json: {
          message: 'Kargo durumu güncellendi',
          data: serialize_shipment(@shipment)
        }
      else
        render json: {
          error: 'Durum güncellenemedi',
          details: @shipment.errors.full_messages
        }, status: :unprocessable_entity
      end
    end
    
    # GET /api/shipment/:id/track
    # Kargo takip et (gerçek zamanlı)
    def track
      cargo_service = Cargo::ServiceFactory.create(@shipment.carrier, @shipment)
      tracking_info = cargo_service.track_shipment
      
      render json: {
        data: {
          shipment: serialize_shipment(@shipment),
          tracking: tracking_info
        }
      }
    rescue StandardError => e
      Rails.logger.error "Kargo takip hatası: #{e.message}"
      render json: {
        error: 'Takip bilgisi alınamadı',
        details: e.message
      }, status: :internal_server_error
    end
    
    # POST /api/shipment/:id/cancel
    # Kargo iptal et (Admin only)
    def cancel
      unless current_user.admin?
        return render json: { error: 'Yetkisiz erişim' }, status: :forbidden
      end
      
      if @shipment.delivered?
        return render json: {
          error: 'Teslim edilmiş kargo iptal edilemez'
        }, status: :unprocessable_entity
      end
      
      cargo_service = Cargo::ServiceFactory.create(@shipment.carrier, @shipment)
      
      if cargo_service.cancel_shipment
        @shipment.update!(status: :returned, notes: "İptal edildi: #{params[:reason]}")
        
        @shipment.admin_notes.create!(
          note: "Kargo iptal edildi - #{params[:reason]}",
          author: current_user
        )
        
        render json: {
          message: 'Kargo iptal edildi',
          data: serialize_shipment(@shipment)
        }
      else
        render json: {
          error: 'Kargo iptal edilemedi'
        }, status: :unprocessable_entity
      end
    rescue StandardError => e
      Rails.logger.error "Kargo iptal hatası: #{e.message}"
      render json: {
        error: 'İptal işlemi başarısız',
        details: e.message
      }, status: :internal_server_error
    end
    
    private
    
    def set_shipment
      @shipment = Shipment.includes(:order).find(params[:id])
    end
    
    def require_admin_for_create!
      unless current_user.admin?
        render json: { error: 'Sadece adminler kargo oluşturabilir' }, status: :forbidden
      end
    end
    
    def require_admin_or_owner!
      unless current_user.admin? || @shipment.order.user_id == current_user.id
        render json: { error: 'Yetkisiz erişim' }, status: :forbidden
      end
    end
    
    def serialize_shipment(shipment, include_order: false)
      data = {
        id: shipment.id,
        tracking_number: shipment.tracking_number,
        carrier: shipment.carrier,
        carrier_name: shipment.carrier_name,
        status: shipment.status,
        shipped_at: shipment.shipped_at&.iso8601,
        delivered_at: shipment.delivered_at&.iso8601,
        estimated_delivery: shipment.estimated_delivery&.iso8601,
        estimated_days: shipment.estimated_days,
        delayed: shipment.delayed?,
        tracking_url: shipment.tracking_url,
        notes: shipment.notes,
        created_at: shipment.created_at.iso8601,
        updated_at: shipment.updated_at.iso8601,
        order_id: shipment.order_id.to_s
      }
      
      if include_order && shipment.order.present?
        data[:order] = {
          id: shipment.order.id,
          order_number: shipment.order.order_number,
          status: shipment.order.status,
          total: shipment.order.total.format,
          customer_name: shipment.order.user&.name,
          customer_email: shipment.order.user&.email
        }
      end
      
      data
    end
  end
end
