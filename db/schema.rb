# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_30_183725) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "addresses", force: :cascade do |t|
    t.string "address_line1"
    t.string "address_line2"
    t.integer "address_type"
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.string "name"
    t.string "phone"
    t.string "postal_code"
    t.string "state"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_addresses_on_user_id"
  end

  create_table "admin_notes", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.datetime "created_at", null: false
    t.text "note", null: false
    t.bigint "related_id", null: false
    t.string "related_type", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_admin_notes_on_author_id"
    t.index ["related_type", "related_id"], name: "index_admin_notes_on_related_type_and_related_id"
  end

  create_table "categories", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.text "description"
    t.string "image_url"
    t.text "meta_description"
    t.string "meta_keywords"
    t.string "meta_title"
    t.string "name", null: false
    t.integer "parent_id"
    t.integer "position", default: 0
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_categories_on_parent_id"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "dealer_balance_transactions", force: :cascade do |t|
    t.integer "amount_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.bigint "dealer_balance_id", null: false
    t.text "note"
    t.bigint "order_id"
    t.string "transaction_type", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_dealer_balance_transactions_on_created_at"
    t.index ["dealer_balance_id"], name: "index_dealer_balance_transactions_on_dealer_balance_id"
    t.index ["order_id"], name: "index_dealer_balance_transactions_on_order_id"
    t.index ["transaction_type"], name: "index_dealer_balance_transactions_on_transaction_type"
  end

  create_table "dealer_balances", force: :cascade do |t|
    t.integer "balance_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "credit_limit_cents", default: 0
    t.string "currency", default: "USD", null: false
    t.bigint "dealer_id", null: false
    t.datetime "last_transaction_at"
    t.datetime "updated_at", null: false
    t.index ["dealer_id"], name: "index_dealer_balances_on_dealer_id", unique: true
  end

  create_table "dealer_discounts", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.bigint "dealer_id", null: false
    t.decimal "discount_percent", precision: 5, scale: 2, default: "0.0", null: false
    t.bigint "product_id", null: false
    t.datetime "updated_at", null: false
    t.index ["dealer_id", "product_id"], name: "index_dealer_discounts_on_dealer_id_and_product_id", unique: true
    t.index ["dealer_id"], name: "index_dealer_discounts_on_dealer_id"
    t.index ["product_id"], name: "index_dealer_discounts_on_product_id"
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "exp"
    t.string "jti"
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti"
  end

  create_table "notification_logs", force: :cascade do |t|
    t.string "channel", null: false
    t.datetime "created_at", null: false
    t.string "error_message"
    t.bigint "notification_template_id"
    t.jsonb "payload", default: {}
    t.string "recipient", null: false
    t.datetime "sent_at"
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["channel"], name: "index_notification_logs_on_channel"
    t.index ["created_at"], name: "index_notification_logs_on_created_at"
    t.index ["notification_template_id"], name: "index_notification_logs_on_notification_template_id"
    t.index ["status"], name: "index_notification_logs_on_status"
    t.index ["user_id"], name: "index_notification_logs_on_user_id"
  end

  create_table "notification_templates", force: :cascade do |t|
    t.boolean "active", default: true
    t.text "body", null: false
    t.string "channel", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "subject"
    t.datetime "updated_at", null: false
    t.index ["channel"], name: "index_notification_templates_on_channel"
    t.index ["name", "channel"], name: "index_notification_templates_on_name_and_channel", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.string "action"
    t.bigint "actor_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "data"
    t.bigint "notifiable_id", null: false
    t.string "notifiable_type", null: false
    t.datetime "read_at"
    t.bigint "recipient_id", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_notifications_on_actor_id"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["recipient_id"], name: "index_notifications_on_recipient_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency"
    t.bigint "order_id", null: false
    t.integer "price_cents"
    t.bigint "product_id", null: false
    t.integer "quantity"
    t.datetime "updated_at", null: false
    t.index ["order_id", "product_id"], name: "index_order_items_on_order_and_product"
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "order_lines", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "note"
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.jsonb "selected_options"
    t.integer "tax_cents", default: 0
    t.decimal "tax_rate", precision: 5, scale: 4, default: "0.2"
    t.integer "total_cents", null: false
    t.integer "unit_price_cents", null: false
    t.datetime "updated_at", null: false
    t.bigint "variant_id"
    t.index ["order_id", "product_id", "variant_id"], name: "index_order_lines_on_order_id_and_product_id_and_variant_id"
    t.index ["order_id"], name: "index_order_lines_on_order_id"
    t.index ["product_id"], name: "index_order_lines_on_product_id"
    t.index ["variant_id"], name: "index_order_lines_on_variant_id"
  end

  create_table "order_status_logs", force: :cascade do |t|
    t.datetime "changed_at", null: false
    t.datetime "created_at", null: false
    t.string "from_status"
    t.bigint "order_id", null: false
    t.string "to_status", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["order_id", "changed_at"], name: "index_order_status_logs_on_order_id_and_changed_at"
    t.index ["order_id"], name: "index_order_status_logs_on_order_id"
    t.index ["user_id"], name: "index_order_status_logs_on_user_id"
  end

  create_table "orders", force: :cascade do |t|
    t.jsonb "billing_address", default: {}
    t.datetime "cancelled_at"
    t.bigint "coupon_id"
    t.datetime "created_at", null: false
    t.integer "created_by_marketer_id"
    t.string "currency"
    t.integer "discount_cents", default: 0, null: false
    t.jsonb "metadata", default: {}
    t.text "notes"
    t.datetime "paid_at"
    t.string "payment_method"
    t.string "payment_status", default: "pending"
    t.string "production_status", default: "pending"
    t.datetime "shipped_at"
    t.jsonb "shipping_address", default: {}
    t.integer "shipping_cents", default: 0, null: false
    t.integer "status"
    t.integer "subtotal_cents", default: 0, null: false
    t.integer "tax_cents", default: 0, null: false
    t.integer "total_cents"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["coupon_id"], name: "index_orders_on_coupon_id"
    t.index ["created_by_marketer_id"], name: "index_orders_on_created_by_marketer_id"
    t.index ["discount_cents"], name: "index_orders_on_discount_cents"
    t.index ["paid_at"], name: "index_orders_on_paid_at"
    t.index ["payment_method"], name: "index_orders_on_payment_method"
    t.index ["payment_status"], name: "index_orders_on_payment_status"
    t.index ["production_status"], name: "index_orders_on_production_status"
    t.index ["shipped_at"], name: "index_orders_on_shipped_at"
    t.index ["status", "created_at"], name: "index_orders_on_status_and_created_at"
    t.index ["user_id", "status", "created_at"], name: "index_orders_on_user_status_date"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "product_option_values", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "meta", default: {}
    t.string "name", null: false
    t.integer "position", default: 0
    t.integer "price_cents", default: 0, null: false
    t.string "price_mode", default: "flat", null: false
    t.bigint "product_option_id", null: false
    t.datetime "updated_at", null: false
    t.index ["product_option_id", "name"], name: "index_product_option_values_on_product_option_id_and_name", unique: true
    t.index ["product_option_id", "position"], name: "index_product_option_values_on_product_option_id_and_position"
    t.index ["product_option_id"], name: "index_product_option_values_on_product_option_id"
  end

  create_table "product_options", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "option_type", default: "select", null: false
    t.integer "position", default: 0
    t.bigint "product_id", null: false
    t.boolean "required", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "name"], name: "index_product_options_on_product_id_and_name", unique: true
    t.index ["product_id", "position"], name: "index_product_options_on_product_id_and_position"
    t.index ["product_id"], name: "index_product_options_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.boolean "active", default: true
    t.integer "base_price_cents", default: 0
    t.string "brand"
    t.bigint "category_id"
    t.integer "cost_price_cents", default: 0
    t.datetime "created_at", null: false
    t.string "currency"
    t.text "description"
    t.boolean "featured", default: false
    t.text "meta_description"
    t.string "meta_title"
    t.integer "price_cents"
    t.jsonb "properties", default: {}
    t.text "short_description"
    t.string "sku"
    t.string "sku_prefix"
    t.string "slug"
    t.string "tags", default: [], array: true
    t.decimal "tax_rate", precision: 5, scale: 4, default: "0.2"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_products_on_active"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["properties"], name: "index_products_on_properties", using: :gin
    t.index ["sku"], name: "index_products_on_sku", unique: true
    t.index ["slug"], name: "index_products_on_slug", unique: true
  end

  create_table "projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "due_date"
    t.string "name"
    t.datetime "start_date"
    t.integer "status"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "promotions_coupons", force: :cascade do |t|
    t.boolean "active"
    t.string "code"
    t.datetime "created_at", null: false
    t.integer "discount_type"
    t.datetime "ends_at"
    t.integer "min_order_amount_cents"
    t.string "min_order_amount_currency"
    t.datetime "starts_at"
    t.datetime "updated_at", null: false
    t.integer "usage_count"
    t.integer "usage_limit"
    t.decimal "value"
    t.index ["code"], name: "index_promotions_coupons_on_code"
  end

  create_table "quote_lines", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "note"
    t.bigint "product_id", null: false
    t.string "product_title", null: false
    t.integer "quantity", default: 1, null: false
    t.bigint "quote_id", null: false
    t.integer "total_cents", default: 0, null: false
    t.integer "unit_price_cents", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "variant_id"
    t.string "variant_name"
    t.index ["product_id"], name: "index_quote_lines_on_product_id"
    t.index ["quote_id"], name: "index_quote_lines_on_quote_id"
    t.index ["variant_id"], name: "index_quote_lines_on_variant_id"
  end

  create_table "quotes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.string "currency", default: "USD", null: false
    t.text "notes"
    t.string "quote_number", null: false
    t.integer "shipping_cents", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.integer "subtotal_cents", default: 0, null: false
    t.integer "tax_cents", default: 0, null: false
    t.integer "total_cents", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.date "valid_until", null: false
    t.index ["created_by_id"], name: "index_quotes_on_created_by_id"
    t.index ["quote_number"], name: "index_quotes_on_quote_number", unique: true
    t.index ["status"], name: "index_quotes_on_status"
    t.index ["user_id"], name: "index_quotes_on_user_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.boolean "approved", default: false, null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.string "guest_email"
    t.bigint "product_id", null: false
    t.integer "rating", null: false
    t.string "reviewer_ip"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["product_id", "approved"], name: "index_reviews_on_product_id_and_approved"
    t.index ["product_id"], name: "index_reviews_on_product_id"
    t.index ["reviewer_ip", "created_at"], name: "index_reviews_on_reviewer_ip_and_created_at"
    t.index ["user_id", "created_at"], name: "index_reviews_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.string "value_type", default: "string"
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "shared_option_values", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0
    t.integer "price_cents", default: 0, null: false
    t.string "price_mode", default: "flat", null: false
    t.bigint "shared_option_id", null: false
    t.datetime "updated_at", null: false
    t.index ["shared_option_id", "name"], name: "index_shared_option_values_on_shared_option_id_and_name", unique: true
    t.index ["shared_option_id"], name: "index_shared_option_values_on_shared_option_id"
  end

  create_table "shared_options", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "option_type", default: "select", null: false
    t.integer "position", default: 0
    t.boolean "required", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_shared_options_on_name", unique: true
  end

  create_table "shipments", force: :cascade do |t|
    t.string "carrier", null: false
    t.datetime "created_at", null: false
    t.datetime "delivered_at"
    t.date "estimated_delivery"
    t.text "notes"
    t.bigint "order_id", null: false
    t.datetime "shipped_at"
    t.integer "status", default: 0, null: false
    t.string "tracking_number", null: false
    t.datetime "updated_at", null: false
    t.index ["carrier"], name: "index_shipments_on_carrier"
    t.index ["order_id"], name: "index_shipments_on_order_id"
    t.index ["status"], name: "index_shipments_on_status"
    t.index ["tracking_number"], name: "index_shipments_on_tracking_number", unique: true
  end

  create_table "sliders", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "button_link"
    t.string "button_text"
    t.datetime "created_at", null: false
    t.integer "display_order", default: 0, null: false
    t.string "image_url"
    t.text "subtitle"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_sliders_on_active"
    t.index ["display_order"], name: "index_sliders_on_display_order"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.text "address"
    t.string "city"
    t.string "company"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.boolean "email_notifications", default: true
    t.string "encrypted_password", default: "", null: false
    t.string "name"
    t.jsonb "notification_preferences", default: {}
    t.string "phone"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role"
    t.boolean "sms_notifications", default: false
    t.datetime "updated_at", null: false
    t.boolean "whatsapp_notifications", default: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "variants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", default: "USD"
    t.jsonb "options", default: {}
    t.integer "price_cents", null: false
    t.bigint "product_id", null: false
    t.string "sku", null: false
    t.integer "stock", default: 0
    t.datetime "updated_at", null: false
    t.index ["options"], name: "index_variants_on_options", using: :gin
    t.index ["product_id"], name: "index_variants_on_product_id"
    t.index ["sku"], name: "index_variants_on_sku", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "addresses", "users"
  add_foreign_key "admin_notes", "users", column: "author_id"
  add_foreign_key "dealer_balance_transactions", "dealer_balances"
  add_foreign_key "dealer_balance_transactions", "orders"
  add_foreign_key "dealer_balances", "users", column: "dealer_id"
  add_foreign_key "dealer_discounts", "products"
  add_foreign_key "dealer_discounts", "users", column: "dealer_id"
  add_foreign_key "notification_logs", "notification_templates"
  add_foreign_key "notification_logs", "users"
  add_foreign_key "notifications", "users", column: "actor_id"
  add_foreign_key "notifications", "users", column: "recipient_id"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "order_lines", "orders"
  add_foreign_key "order_lines", "products"
  add_foreign_key "order_lines", "variants"
  add_foreign_key "order_status_logs", "orders"
  add_foreign_key "order_status_logs", "users"
  add_foreign_key "orders", "promotions_coupons", column: "coupon_id"
  add_foreign_key "orders", "users"
  add_foreign_key "product_option_values", "product_options"
  add_foreign_key "product_options", "products"
  add_foreign_key "products", "categories"
  add_foreign_key "projects", "users"
  add_foreign_key "quote_lines", "products"
  add_foreign_key "quote_lines", "quotes"
  add_foreign_key "quote_lines", "variants"
  add_foreign_key "quotes", "users"
  add_foreign_key "quotes", "users", column: "created_by_id"
  add_foreign_key "reviews", "products"
  add_foreign_key "reviews", "users"
  add_foreign_key "shared_option_values", "shared_options"
  add_foreign_key "shipments", "orders"
  add_foreign_key "variants", "products"
end
