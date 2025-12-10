# coding: utf-8

require_relative 'spec_helper'
require_relative 'builder'

RSpec.describe 'Iyzipay' do
  before :all do
    @options = Iyzipay::Options.new
    @options.api_key = SpecOptions::API_KEY
    @options.secret_key = SpecOptions::SECRET_KEY
    @options.base_url = SpecOptions::BASE_URL
  end

  it 'should initialize pecco' do
    buyer = {
        id: 'BY789',
        name: 'John',
        surname: 'Doe',
        identityNumber: '74300864791',
        email: 'email@email.com',
        gsmNumber: '+905350000000',
        registrationDate: '2013-04-21 15:12:09',
        lastLoginDate: '2015-10-05 12:43:35',
        registrationAddress: 'Nidakule Göztepe, Merdivenköy Mah. Bora Sok. No:1',
        city: 'Istanbul',
        country: 'Turkey',
        zipCode: '34732',
        ip: '85.34.78.112'
    }
    address = {
        address: 'Nidakule Göztepe, Merdivenköy Mah. Bora Sok. No:1',
        zipCode: '34732',
        contactName: 'John Doe',
        city: 'Istanbul',
        country: 'Turkey'
    }

    item1 = {
        id: 'BI101',
        name: 'Binocular',
        category1: 'Collectibles',
        category2: 'Accessories',
        itemType: Iyzipay::Model::BasketItemType::PHYSICAL,
        price: '30000'
    }
    item2 = {
        id: 'BI102',
        name: 'Game code',
        category1: 'Game',
        category2: 'Online Game Items',
        itemType: Iyzipay::Model::BasketItemType::VIRTUAL,
        price: '50000'
    }
    item3 = {
        id: 'BI103',
        name: 'Usb',
        category1: 'Electronics',
        category2: 'Usb / Cable',
        itemType: Iyzipay::Model::BasketItemType::PHYSICAL,
        price: '20000'
    }
    request = {
        locale: Iyzipay::Model::Locale::TR,
        conversationId: '123456789',
        price: '100000',
        paidPrice: '120000',
        basketId: 'B67832',
        paymentGroup: Iyzipay::Model::PaymentGroup::LISTING,
        callbackUrl: 'https://www.merchant.com/callback',
        currency: Iyzipay::Model::Currency::IRR,
        buyer: buyer,
        billingAddress: address,
        shippingAddress: address,
        basketItems: [item1, item2, item3]
    }
    pecco_initialize = Iyzipay::Model::PeccoInitialize.new.create(request, @options)
    begin
      $stderr.puts pecco_initialize.inspect
      pecco_initialize = JSON.parse(pecco_initialize)
      unless pecco_initialize['htmlContent'].nil?
        $stdout.puts Base64.decode64(pecco_initialize['htmlContent']).inspect
        expect(pecco_initialize['status']).to eq('success')
        expect(pecco_initialize['locale']).to eq('tr')
        expect(pecco_initialize['systemTime']).not_to be_nil
        expect(pecco_initialize['conversationId']).to eq('123456789')
        expect(pecco_initialize['htmlContent']).not_to be_nil
      end
    rescue
      $stderr.puts 'oops'
      raise
    end
  end

  it 'should create pecco payment' do

    # This test needs manual payment from Pecco on sandbox environment. So it does not contain any assertions.
    pecco_initialize = Builder::PeccoInitializeBuilder.new.create_pecco_initialize(@options)

    request = {
        locale: Iyzipay::Model::Locale::TR,
        conversationId: '123456789',
        token: pecco_initialize['token']
    }
    pecco_payment = Iyzipay::Model::PeccoPayment.new.create(request, @options)

    begin
      $stdout.puts pecco_payment.inspect
    rescue
      $stdout.puts 'oops'
      raise
    end
  end

  after :each do
  end
end
