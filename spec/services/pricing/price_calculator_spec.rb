# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Pricing::PriceCalculator, type: :service do
  let(:product) { create(:product, price_cents: 100000) } # $1000
  let(:variant) { create(:variant, product: product, price_cents: 100000, sku: 'VAR-001') }
  let(:dealer) { create(:user, role: :dealer) }
  
  describe '#call' do
    context 'basic calculation without options or discount' do
      it 'calculates correct price for quantity 1' do
        calculator = described_class.new(
          variant: variant,
          quantity: 1,
          tax_rate: 0.20
        )
        
        result = calculator.call
        
        expect(result[:unit_price_cents]).to eq(100000)
        expect(result[:quantity]).to eq(1)
        expect(result[:subtotal_cents]).to eq(100000)
        expect(result[:options_total_cents]).to eq(0)
        expect(result[:discount_cents]).to eq(0)
        expect(result[:tax_cents]).to eq(20000) # 100000 * 0.20
        expect(result[:total_cents]).to eq(120000) # 100000 + 20000
      end
      
      it 'calculates correct price for quantity 10' do
        calculator = described_class.new(
          variant: variant,
          quantity: 10,
          tax_rate: 0.20
        )
        
        result = calculator.call
        
        expect(result[:subtotal_cents]).to eq(1000000) # 100000 * 10
        expect(result[:tax_cents]).to eq(200000) # 1000000 * 0.20
        expect(result[:total_cents]).to eq(1200000) # 1000000 + 200000
      end
    end
    
    context 'with flat price options' do
      let(:warranty_option) do
        create(:product_option, 
          product: product, 
          name: 'Warranty', 
          option_type: 'select'
        )
      end
      
      let(:warranty_value) do
        create(:product_option_value,
          product_option: warranty_option,
          name: '1 Year Extended',
          price_cents: 17500, # $175
          price_mode: 'flat'
        )
      end
      
      it 'adds flat option price once regardless of quantity' do
        calculator = described_class.new(
          variant: variant,
          quantity: 10,
          selected_option_values: [warranty_value],
          tax_rate: 0.20
        )
        
        result = calculator.call
        
        # Variant: 100000 * 10 = 1000000
        # Option (flat): 17500 * 1 = 17500
        # Subtotal: 1017500
        # Tax: 1017500 * 0.20 = 203500
        # Total: 1017500 + 203500 = 1221000
        
        expect(result[:subtotal_cents]).to eq(1000000)
        expect(result[:options_total_cents]).to eq(17500)
        expect(result[:taxable_amount_cents]).to eq(1017500)
        expect(result[:tax_cents]).to eq(203500)
        expect(result[:total_cents]).to eq(1221000)
        
        # Check breakdown
        option_breakdown = result[:options_breakdown].first
        expect(option_breakdown[:price_mode]).to eq('flat')
        expect(option_breakdown[:quantity]).to eq(1)
        expect(option_breakdown[:total_cents]).to eq(17500)
      end
      
      it 'handles multiple flat options' do
        engraving_option = create(:product_option, product: product, name: 'Engraving')
        engraving_value = create(:product_option_value,
          product_option: engraving_option,
          price_cents: 5000, # $50
          price_mode: 'flat'
        )
        
        calculator = described_class.new(
          variant: variant,
          quantity: 2,
          selected_option_values: [warranty_value, engraving_value],
          tax_rate: 0.20
        )
        
        result = calculator.call
        
        # Variant: 100000 * 2 = 200000
        # Options: 17500 + 5000 = 22500
        # Subtotal: 222500
        # Tax: 222500 * 0.20 = 44500
        # Total: 222500 + 44500 = 267000
        
        expect(result[:options_total_cents]).to eq(22500)
        expect(result[:total_cents]).to eq(267000)
      end
    end
    
    context 'with per-unit price options' do
      let(:battery_option) do
        create(:product_option, 
          product: product, 
          name: 'Extra Batteries'
        )
      end
      
      let(:battery_value) do
        create(:product_option_value,
          product_option: battery_option,
          name: '2 Batteries',
          price_cents: 500, # $5 per unit
          price_mode: 'per_unit'
        )
      end
      
      it 'multiplies per-unit option by quantity' do
        calculator = described_class.new(
          variant: variant,
          quantity: 10,
          selected_option_values: [battery_value],
          tax_rate: 0.20
        )
        
        result = calculator.call
        
        # Variant: 100000 * 10 = 1000000
        # Option (per-unit): 500 * 10 = 5000
        # Subtotal: 1005000
        # Tax: 1005000 * 0.20 = 201000
        # Total: 1005000 + 201000 = 1206000
        
        expect(result[:options_total_cents]).to eq(5000)
        expect(result[:total_cents]).to eq(1206000)
        
        # Check breakdown
        option_breakdown = result[:options_breakdown].first
        expect(option_breakdown[:price_mode]).to eq('per_unit')
        expect(option_breakdown[:quantity]).to eq(10)
        expect(option_breakdown[:total_cents]).to eq(5000)
      end
    end
    
    context 'with dealer discount' do
      let!(:dealer_discount) do
        create(:dealer_discount,
          dealer: dealer,
          product: product,
          discount_percent: 10.0,
          active: true
        )
      end
      
      it 'applies dealer discount before tax' do
        calculator = described_class.new(
          variant: variant,
          quantity: 10,
          dealer: dealer,
          tax_rate: 0.20
        )
        
        result = calculator.call
        
        # Variant: 100000 * 10 = 1000000
        # Discount (10%): 1000000 * 0.10 = 100000
        # After discount: 900000
        # Tax: 900000 * 0.20 = 180000
        # Total: 900000 + 180000 = 1080000
        
        expect(result[:subtotal_cents]).to eq(1000000)
        expect(result[:discount_cents]).to eq(100000)
        expect(result[:discount_percent]).to eq(10.0)
        expect(result[:subtotal_after_discount_cents]).to eq(900000)
        expect(result[:tax_cents]).to eq(180000)
        expect(result[:total_cents]).to eq(1080000)
        expect(result[:has_discount]).to be true
        expect(result[:is_dealer]).to be true
      end
      
      it 'does not apply dealer discount if not active' do
        dealer_discount.update!(active: false)
        
        calculator = described_class.new(
          variant: variant,
          quantity: 1,
          dealer: dealer,
          tax_rate: 0.20
        )
        
        result = calculator.call
        
        expect(result[:discount_cents]).to eq(0)
        expect(result[:has_discount]).to be false
      end
    end
    
    context 'complex scenario: variant + options + dealer discount + tax' do
      let(:warranty_option) { create(:product_option, product: product, name: 'Warranty') }
      let(:warranty_value) do
        create(:product_option_value,
          product_option: warranty_option,
          price_cents: 17500,
          price_mode: 'flat'
        )
      end
      
      let(:battery_option) { create(:product_option, product: product, name: 'Batteries') }
      let(:battery_value) do
        create(:product_option_value,
          product_option: battery_option,
          price_cents: 500,
          price_mode: 'per_unit'
        )
      end
      
      let!(:dealer_discount) do
        create(:dealer_discount,
          dealer: dealer,
          product: product,
          discount_percent: 10.0,
          active: true
        )
      end
      
      it 'calculates all components correctly' do
        # Test case from user requirements:
        # Variant: 1000₺ (100000 cents)
        # Quantity: 10
        # Option flat: 1750₺ (17500 cents) - warranty
        # Option per-unit: 50₺ (500 cents) - batteries
        # Dealer discount: 10%
        # Tax: 20%
        
        calculator = described_class.new(
          variant: variant,
          quantity: 10,
          selected_option_values: [warranty_value, battery_value],
          dealer: dealer,
          tax_rate: 0.20
        )
        
        result = calculator.call
        
        # Step 1: Variant base
        # 100000 * 10 = 1000000
        expect(result[:subtotal_cents]).to eq(1000000)
        
        # Step 2: Dealer discount (10%)
        # 1000000 * 0.10 = 100000
        expect(result[:discount_cents]).to eq(100000)
        
        # Step 3: After discount
        # 1000000 - 100000 = 900000
        expect(result[:subtotal_after_discount_cents]).to eq(900000)
        
        # Step 4: Options
        # Flat: 17500 * 1 = 17500
        # Per-unit: 500 * 10 = 5000
        # Total: 22500
        expect(result[:options_total_cents]).to eq(22500)
        
        # Step 5: Taxable amount
        # 900000 + 22500 = 922500
        expect(result[:taxable_amount_cents]).to eq(922500)
        
        # Step 6: Tax (20%)
        # 922500 * 0.20 = 184500
        expect(result[:tax_cents]).to eq(184500)
        
        # Step 7: Grand total
        # 922500 + 184500 = 1107000
        expect(result[:total_cents]).to eq(1107000)
        
        # Verify breakdown structure
        expect(result[:breakdown]).to have_key(:steps)
        expect(result[:breakdown]).to have_key(:summary)
        expect(result[:breakdown][:steps].length).to be >= 5
      end
    end
    
    context 'different tax rates' do
      it 'calculates with 18% tax' do
        calculator = described_class.new(
          variant: variant,
          quantity: 1,
          tax_rate: 0.18
        )
        
        result = calculator.call
        
        expect(result[:tax_rate]).to eq(0.18)
        expect(result[:tax_cents]).to eq(18000) # 100000 * 0.18
        expect(result[:total_cents]).to eq(118000)
      end
      
      it 'calculates with 0% tax' do
        calculator = described_class.new(
          variant: variant,
          quantity: 1,
          tax_rate: 0.0
        )
        
        result = calculator.call
        
        expect(result[:tax_cents]).to eq(0)
        expect(result[:total_cents]).to eq(100000)
      end
    end
    
    context 'validations' do
      it 'raises error if variant is nil' do
        expect {
          described_class.new(variant: nil, quantity: 1)
        }.to raise_error(ArgumentError, "Variant is required")
      end
      
      it 'raises error if quantity is zero or negative' do
        expect {
          described_class.new(variant: variant, quantity: 0)
        }.to raise_error(ArgumentError, "Quantity must be positive")
        
        expect {
          described_class.new(variant: variant, quantity: -5)
        }.to raise_error(ArgumentError, "Quantity must be positive")
      end
      
      it 'raises error if tax_rate is invalid' do
        expect {
          described_class.new(variant: variant, quantity: 1, tax_rate: -0.1)
        }.to raise_error(ArgumentError, "Tax rate must be between 0 and 1")
        
        expect {
          described_class.new(variant: variant, quantity: 1, tax_rate: 1.5)
        }.to raise_error(ArgumentError, "Tax rate must be between 0 and 1")
      end
      
      it 'raises error if option value belongs to different product' do
        other_product = create(:product)
        other_option = create(:product_option, product: other_product)
        other_value = create(:product_option_value, product_option: other_option)
        
        expect {
          described_class.new(
            variant: variant,
            quantity: 1,
            selected_option_values: [other_value]
          )
        }.to raise_error(ArgumentError, /does not belong to product/)
      end
    end
  end
end
