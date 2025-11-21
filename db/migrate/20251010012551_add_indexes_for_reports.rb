class AddIndexesForReports < ActiveRecord::Migration[7.2]
  def change
    # Optimize orders queries by status and date
    add_index :orders, [:status, :created_at], name: 'index_orders_on_status_and_created_at'
    
    # Optimize order_items queries for aggregations
    add_index :order_items, [:order_id, :product_id], name: 'index_order_items_on_order_and_product'
    
    # Optimize user-based filtering
    add_index :orders, [:user_id, :status, :created_at], name: 'index_orders_on_user_status_date'
    
    # Note: For future optimization, consider creating a materialized view:
    # CREATE MATERIALIZED VIEW sales_summary AS
    # SELECT 
    #   DATE(orders.created_at) as sale_date,
    #   products.id as product_id,
    #   products.title as product_title,
    #   SUM(order_items.total_cents) as revenue_cents,
    #   SUM(order_items.quantity) as quantity,
    #   COUNT(DISTINCT orders.id) as orders_count
    # FROM orders
    # JOIN order_items ON order_items.order_id = orders.id
    # JOIN products ON products.id = order_items.product_id
    # WHERE orders.status IN ('paid', 'shipped')
    # GROUP BY DATE(orders.created_at), products.id, products.title;
    #
    # REFRESH: REFRESH MATERIALIZED VIEW CONCURRENTLY sales_summary;
  end
end
