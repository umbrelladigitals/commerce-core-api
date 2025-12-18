Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  
  # Sidekiq Web UI
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
  
  devise_for :users,
    path: '',
    path_names: {
      sign_in: 'login',
      sign_out: 'logout',
      registration: 'signup'
    },
    controllers: {
      sessions: 'users/sessions',
      registrations: 'users/registrations'
    }

  # API namespace
  namespace :api do
    namespace :v1 do
      # Categories
      resources :categories, only: [:index, :show]
      
      # Sliders
      resources :sliders, only: [:index, :show, :create, :update, :destroy]
      
      # Quotes
      resources :quotes do
        member do
          post :send_quote
          post :accept
          post :reject
        end
      end
      
      # Cart routes
      resource :cart, only: [:show], controller: 'cart' do
        post :add
        post :apply_coupon
        delete :remove_coupon
        get 'checkout/preview', action: :checkout_preview
        post :checkout
        delete :clear
        patch 'items/:id', action: :update_item, as: :update_item
        delete 'items/:id', action: :remove_item, as: :remove_item
      end
    end
    
    # Direct routes (simplified)
    resources :categories, controller: 'v1/catalog/categories' do
      member do
        get :products
      end
    end
    
    resources :products, controller: 'v1/catalog/products' do
      resources :variants, controller: 'v1/catalog/variants' do
        member do
          patch :update_stock
        end
      end
      resources :reviews, controller: 'v1/reviews', only: [:create]
    end
    
    # Payment routes
    scope :payment, module: :v1 do
      post 'confirm', to: 'payment#confirm'
      post 'webhook', to: 'payment#webhook'
      
      # PayTR routes
      post 'paytr/callback', to: 'payment#paytr_callback'
      get 'paytr/success', to: 'payment#paytr_success'
      get 'paytr/fail', to: 'payment#paytr_fail'
    end
    
    # Shipment (Kargo) routes
    scope :shipment do
      get '/', to: 'shipment#index', as: :shipments
      post 'guest_track', to: 'shipment#guest_track'
      get ':id', to: 'shipment#show', as: :shipment
      post 'create', to: 'shipment#create'
      patch ':id/update_status', to: 'shipment#update_status', as: :update_shipment_status
      get ':id/track', to: 'shipment#track', as: :track_shipment
      post ':id/cancel', to: 'shipment#cancel', as: :cancel_shipment
    end
    
    # Dealer Dashboard routes
    namespace :dealer do
      get 'dashboard', to: 'dashboard#dashboard'
      get 'orders', to: 'dashboard#orders'
      get 'discounts', to: 'dashboard#discounts'
      get 'balance', to: 'dashboard#balance'
      get 'balance/history', to: 'dashboard#balance_history'
      post 'balance/topup', to: 'dashboard#topup'
    end

    # Versioned routes (v1)
    namespace :v1 do
      # Bank accounts (public endpoint for payment page)
      resources :bank_accounts, only: [:index]
      
      # Payments
      resources :payments, only: [:create] do
        collection do
          post :callback
          post :iyzico_webhook
        end
      end

      # Users domain
      namespace :users do
        resource :profile, only: [:show, :update], controller: 'profiles'
        resources :addresses
        post 'change_password', to: 'profiles#change_password'
        patch 'notification_settings', to: 'profiles#update_notification_settings'
      end

      # Catalog domain
      namespace :catalog do
        resources :categories do
          member do
            get :products
          end
        end
        
        resources :products do
          resources :variants do
            member do
              patch :update_stock
            end
          end
        end
      end

      # Marketer routes (Pazarlamacı)
      namespace :marketer do
        get 'dashboard', to: 'dashboard#index'
        resources :customers, only: [:index, :show, :create]
        resources :orders, only: [:index, :show, :create]
        resources :quotes, only: [:index, :show, :create, :update, :destroy] do
          member do
            post :send_quote, path: 'send'
          end
        end
      end

      # Manufacturer routes (Üretici)
      namespace :manufacturer do
        get 'dashboard', to: 'dashboard#index'
        resources :orders, only: [:index, :show] do
          member do
            patch :update_status
          end
        end
      end

      # Admin routes
      namespace :admin do
        post 'uploads', to: 'uploads#create'
        get 'dashboard/stats', to: 'dashboard#stats'
        # Admin Catalog
        namespace :catalog do
          resources :categories
        end

        # Admin Products CRUD
        resources :products, only: [:index, :show, :create, :update, :destroy] do
          resources :product_options, only: [:index, :show, :create, :update, :destroy] do
            member do
              patch :reorder
            end
            collection do
              post :import_shared
            end
          end
        end

        # Shared Options
        resources :shared_options

        resources :product_options, only: [] do
          resources :values, controller: 'product_option_values', only: [:index, :show, :create, :update, :destroy] do
            member do
              patch :reorder
            end
          end
        end
        
        # Notifications
        resources :notification_templates
        
        namespace :notifications do
          post :send, to: 'notifications#send_bulk'
          get :logs, to: 'notifications#logs'
          get 'logs/:id', to: 'notifications#show_log'
        end
        
        # Reviews
        resources :reviews, only: [:index, :show, :destroy] do
          member do
            patch :approve
            patch :reject
          end
        end
        
        # Admin Notes
        resources :notes, only: [:index, :show, :create, :update, :destroy]
        
        # Admin Coupons
        resources :coupons, only: [:index, :show, :create, :destroy]

        # Admin Shipments
        resources :shipments, only: [:index, :show, :update]

        # Admin Sliders
        resources :sliders, only: [:index, :show, :create, :update, :destroy]

        # Admin Pricing
        namespace :pricing do
          post 'bulk-upload', to: 'pricing#bulk_upload'
        end

        # Admin Users
        resources :users, only: [:index, :show, :create, :update, :destroy] do
          member do
            post :add_balance
          end
        end
        
        # Admin Orders (bayi/müşteri adına sipariş oluşturma)
        resources :orders, only: [:index, :show, :create, :update, :destroy]
        
        # Quotes (Teklifler/Proforma)
        resources :quotes, only: [:index, :show, :create, :update, :destroy] do
          member do
            post :convert_to_order, path: 'convert'
            post :send_quote, path: 'send'
          end
        end
      end

      # Orders domain
      namespace :orders do
        resources :orders do
          member do
            patch :cancel
          end
        end
      end
      
      # Pricing domain
      namespace :pricing do
        post 'preview', to: 'pricing#preview'
        post 'cart-total', to: 'pricing#cart_total'
      end
      
      # B2B domain
      namespace :b2b do
        resources :dealer_discounts do
          member do
            patch :toggle_active
          end
        end
        
        resources :dealer_balances, only: [:index, :show] do
          member do
            post :add_credit
            patch :update_credit_limit
          end
        end
        
        get 'my_balance', to: 'dealer_balances#my_balance'
      end
      
      # Manufacturing domain
      namespace :manufacturing do
        resources :orders, only: [:index, :show] do
          member do
            patch :production_status, action: :update_production_status
          end
        end
      end
    end
    
    # Reports domain
    namespace :reports do
      get 'sales', to: 'sales#index'
    end
    
    # Admin domain
    namespace :admin do
      resources :settings, only: [:index, :show, :update], param: :key
      resources :bank_accounts, only: [:index, :create, :update, :destroy]
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Root
  root to: proc { [200, {}, ["Commerce Core API - #{Rails.env}"]] }
end
