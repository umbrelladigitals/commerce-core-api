require 'swagger_helper'

RSpec.describe 'Catalog API', type: :request do
  path '/api/v1/catalog/products' do
    get 'List all products' do
      tags 'Products'
      produces 'application/json'

      response '200', 'products found' do
        schema type: :array,
          items: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              description: { type: :string },
              price_cents: { type: :integer },
              currency: { type: :string }
            },
            required: ['id', 'name', 'price_cents']
          }

        run_test!
      end
    end

    post 'Create a product' do
      tags 'Products'
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :product, in: :body, schema: {
        type: :object,
        properties: {
          product: {
            type: :object,
            properties: {
              name: { type: :string },
              description: { type: :string },
              price_cents: { type: :integer },
              currency: { type: :string }
            },
            required: ['name', 'price_cents']
          }
        }
      }

      response '201', 'product created' do
        let(:product) { { product: { name: 'Test Product', price_cents: 1000, currency: 'USD' } } }
        run_test!
      end

      response '422', 'invalid request' do
        let(:product) { { product: { name: '' } } }
        run_test!
      end
    end
  end

  path '/api/v1/catalog/products/{id}' do
    parameter name: :id, in: :path, type: :integer

    get 'Retrieve a product' do
      tags 'Products'
      produces 'application/json'

      response '200', 'product found' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            name: { type: :string },
            description: { type: :string },
            price_cents: { type: :integer },
            currency: { type: :string }
          }

        let(:id) { Catalog::Product.create(name: 'Test', price_cents: 1000, currency: 'USD').id }
        run_test!
      end

      response '404', 'product not found' do
        let(:id) { 'invalid' }
        run_test!
      end
    end

    patch 'Update a product' do
      tags 'Products'
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :product, in: :body, schema: {
        type: :object,
        properties: {
          product: {
            type: :object,
            properties: {
              name: { type: :string },
              description: { type: :string },
              price_cents: { type: :integer },
              currency: { type: :string }
            }
          }
        }
      }

      response '200', 'product updated' do
        let(:id) { Catalog::Product.create(name: 'Test', price_cents: 1000, currency: 'USD').id }
        let(:product) { { product: { name: 'Updated Name' } } }
        run_test!
      end
    end

    delete 'Delete a product' do
      tags 'Products'

      response '204', 'product deleted' do
        let(:id) { Catalog::Product.create(name: 'Test', price_cents: 1000, currency: 'USD').id }
        run_test!
      end
    end
  end
end
