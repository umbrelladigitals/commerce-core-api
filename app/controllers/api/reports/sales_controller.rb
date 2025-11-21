# frozen_string_literal: true

module Api
  module Reports
    class SalesController < ApplicationController
      before_action :authenticate_user!
      before_action :validate_date_params
      
      # GET /api/reports/sales
      # Params: start_date, end_date, dealer_id, product_id, format (json/csv)
      def index
        @report_data = generate_sales_report
        
        if params[:format] == 'csv' || request.format.csv?
          send_csv_file(@report_data)
        else
          render json: format_json_response(@report_data)
        end
      end
      
      private
      
      def generate_sales_report
        # Base query - only paid and shipped orders
  orders = ::Orders::Order.where(status: [:paid, :shipped])
        
        # Apply date range filter
        if params[:start_date].present?
          start_date = Date.parse(params[:start_date])
          orders = orders.where('orders.created_at >= ?', start_date.beginning_of_day)
        end
        
        if params[:end_date].present?
          end_date = Date.parse(params[:end_date])
          orders = orders.where('orders.created_at <= ?', end_date.end_of_day)
        end
        
        # Apply dealer filter
        if params[:dealer_id].present?
          orders = orders.where(user_id: params[:dealer_id])
        end
        
        # Get order IDs for efficient querying
        order_ids = orders.pluck(:id)
        
        # Build order_lines query with product filter if needed
  order_lines_scope = ::Orders::OrderLine.unscoped.where(order_id: order_ids)
        if params[:product_id].present?
          order_lines_scope = order_lines_scope.where(product_id: params[:product_id])
        end
        
        # Aggregate totals
        totals = order_lines_scope
          .select(
            'SUM(order_lines.total_cents) as total_revenue_cents',
            'SUM(order_lines.quantity) as total_quantity',
            'COUNT(DISTINCT order_lines.order_id) as orders_count'
          )
          .take  # Use take instead of first to avoid ordering issues
        
        # Product breakdown (reuse the same scope with product filter)
        product_breakdown_query = order_lines_scope
          .joins(:product)
          .select(
            'products.id as product_id',
            'products.title as product_title',
            'products.sku as product_sku',
            'SUM(order_lines.total_cents) as revenue_cents',
            'SUM(order_lines.quantity) as quantity',
            'COUNT(DISTINCT order_lines.order_id) as orders_count',
            'AVG(order_lines.unit_price_cents) as avg_price_cents'
          )
          .group('products.id, products.title, products.sku')
          .order('revenue_cents DESC')
        
        # Apply product filter if specified
        if params[:product_id].present?
          product_breakdown_query = product_breakdown_query.where('products.id = ?', params[:product_id])
        end
        
        product_breakdown = product_breakdown_query.map do |item|
          {
            product_id: item.product_id,
            product_title: item.product_title,
            product_sku: item.product_sku,
            revenue_cents: item.revenue_cents.to_i,
            revenue_formatted: Money.new(item.revenue_cents.to_i, 'USD').format,
            quantity: item.quantity.to_i,
            orders_count: item.orders_count.to_i,
            avg_price_cents: item.avg_price_cents.to_i,
            avg_price_formatted: Money.new(item.avg_price_cents.to_i, 'USD').format
          }
        end
        
        {
          totals: {
            total_revenue_cents: totals&.total_revenue_cents&.to_i || 0,
            total_revenue_formatted: Money.new(totals&.total_revenue_cents&.to_i || 0, 'USD').format,
            total_quantity: totals&.total_quantity&.to_i || 0,
            orders_count: totals&.orders_count&.to_i || 0
          },
          product_breakdown: product_breakdown,
          filters: {
            start_date: params[:start_date],
            end_date: params[:end_date],
            dealer_id: params[:dealer_id],
            product_id: params[:product_id]
          },
          generated_at: Time.current
        }
      end
      
      def format_json_response(report_data)
        {
          success: true,
          data: {
            summary: report_data[:totals],
            breakdown: report_data[:product_breakdown],
            filters_applied: report_data[:filters],
            generated_at: report_data[:generated_at]
          },
          meta: {
            total_products: report_data[:product_breakdown].size,
            currency: 'USD'
          }
        }
      end
      
      def send_csv_file(report_data)
        csv_data = generate_csv(report_data)
        filename = "sales_report_#{Date.current.strftime('%Y%m%d')}.csv"
        
        send_data csv_data,
                  filename: filename,
                  type: 'text/csv',
                  disposition: 'attachment'
      end
      
      def generate_csv(report_data)
        require 'csv'
        
        CSV.generate(headers: true) do |csv|
          # Header row
          csv << [
            'Product ID',
            'Product Title',
            'SKU',
            'Quantity Sold',
            'Revenue (cents)',
            'Revenue (formatted)',
            'Orders Count',
            'Avg Price (cents)',
            'Avg Price (formatted)'
          ]
          
          # Data rows
          report_data[:product_breakdown].each do |item|
            csv << [
              item[:product_id],
              item[:product_title],
              item[:product_sku],
              item[:quantity],
              item[:revenue_cents],
              item[:revenue_formatted],
              item[:orders_count],
              item[:avg_price_cents],
              item[:avg_price_formatted]
            ]
          end
          
          # Summary row
          csv << []
          csv << ['TOTAL', '', '', 
                  report_data[:totals][:total_quantity],
                  report_data[:totals][:total_revenue_cents],
                  report_data[:totals][:total_revenue_formatted],
                  report_data[:totals][:orders_count],
                  '', '']
        end
      end
      
      def validate_date_params
        if params[:start_date].present?
          begin
            Date.parse(params[:start_date])
          rescue ArgumentError
            return render json: { error: 'Invalid start_date format. Use YYYY-MM-DD' }, status: :bad_request
          end
        end
        
        if params[:end_date].present?
          begin
            Date.parse(params[:end_date])
          rescue ArgumentError
            return render json: { error: 'Invalid end_date format. Use YYYY-MM-DD' }, status: :bad_request
          end
        end
        
        if params[:start_date].present? && params[:end_date].present?
          start_date = Date.parse(params[:start_date])
          end_date = Date.parse(params[:end_date])
          
          if start_date > end_date
            return render json: { error: 'start_date cannot be after end_date' }, status: :bad_request
          end
        end
      end
    end
  end
end
