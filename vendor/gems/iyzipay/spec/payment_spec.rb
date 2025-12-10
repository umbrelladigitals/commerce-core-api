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

  it 'should create listing payment' do
    payment_card = {
        cardHolderName: 'John Doe',
        cardNumber: '5528790000000008',
        expireYear: '2030',
        expireMonth: '12',
        cvc: '123',
        registerCard: 0
    }
    buyer = {
        id: 'BY789',
        name: 'John',
        surname: 'Doe',
        gsmNumber: '+905350000000',
        email: 'email@email.com',
        identityNumber: '74300864791',
        lastLoginDate: '2015-10-05 12:43:35',
        registrationDate: '2013-04-21 15:12:09',
        registrationAddress: 'Nidakule Göztepe, Merdivenköy Mah. Bora Sok. No:1',
        ip: '85.34.78.112',
        city: 'Istanbul',
        country: 'Turkey',
        zipCode: '34732'
    }
    address = {
        contactName: 'Jane Doe',
        city: 'Istanbul',
        country: 'Turkey',
        address: 'Nidakule Göztepe, Merdivenköy Mah. Bora Sok. No:1',
        zipCode: '34732'
    }

    item1 = {
        id: 'BI101',
        name: 'Binocular',
        category1: 'Collectibles',
        category2: 'Accessories',
        itemType: Iyzipay::Model::BasketItemType::PHYSICAL,
        price: '0.3'
    }
    item2 = {
        id: 'BI102',
        name: 'Game code',
        category1: 'Game',
        category2: 'Online Game Items',
        itemType: Iyzipay::Model::BasketItemType::VIRTUAL,
        price: '0.5'
    }
    item3 = {
        id: 'BI103',
        name: 'Usb',
        category1: 'Electronics',
        category2: 'Usb / Cable',
        itemType: Iyzipay::Model::BasketItemType::PHYSICAL,
        price: '0.2'
    }
    request = {
        locale: Iyzipay::Model::Locale::TR,
        conversationId: '123456789',
        price: '1',
        paidPrice: '1.1',
        currency: Iyzipay::Model::Currency::TRY,
        installment: 1,
        basketId: 'B67832',
        paymentChannel: Iyzipay::Model::PaymentChannel::WEB,
        paymentGroup: Iyzipay::Model::PaymentGroup::LISTING,
        paymentCard: payment_card,
        buyer: buyer,
        billingAddress: address,
        shippingAddress: address,
        basketItems: [item1, item2, item3]
    }
    payment = Iyzipay::Model::Payment.new.create(request, @options)
    begin
      $stdout.puts payment.inspect
      payment = JSON.parse(payment)
      expect(payment['status']).to eq('success')
      expect(payment['locale']).to eq('tr')
      expect(payment['systemTime']).not_to be_nil
      expect(payment['conversationId']).to eq('123456789')
      expect(payment['price']).to eq(1)
      expect(payment['paidPrice']).to eq(1.1)
      expect(payment['installment']).to eq(1)
    rescue
      $stderr.puts 'oops'
      raise
    end
  end

  it 'should create marketplace payment' do
    # create sub merchant
    sub_merchant = Builder::SubMerchantBuilder.new.create_personal_sub_merchant(@options)

    payment_card = {
        cardHolderName: 'John Doe',
        cardNumber: '5528790000000008',
        expireYear: '2030',
        expireMonth: '12',
        cvc: '123',
        registerCard: 0
    }
    buyer = {
        id: 'BY789',
        name: 'John',
        surname: 'Doe',
        gsmNumber: '+905350000000',
        email: 'email@email.com',
        identityNumber: '74300864791',
        lastLoginDate: '2015-10-05 12:43:35',
        registrationDate: '2013-04-21 15:12:09',
        registrationAddress: 'Nidakule Göztepe, Merdivenköy Mah. Bora Sok. No:1',
        ip: '85.34.78.112',
        city: 'Istanbul',
        country: 'Turkey',
        zipCode: '34732'
    }
    address = {
        contactName: 'Jane Doe',
        city: 'Istanbul',
        country: 'Turkey',
        address: 'Nidakule Göztepe, Merdivenköy Mah. Bora Sok. No:1',
        zipCode: '34732'
    }

    item1 = {
        id: 'BI101',
        name: 'Binocular',
        category1: 'Collectibles',
        category2: 'Accessories',
        itemType: Iyzipay::Model::BasketItemType::PHYSICAL,
        price: '0.3',
        subMerchantKey: sub_merchant['subMerchantKey'],
        subMerchantPrice: '0.27'
    }
    item2 = {
        id: 'BI102',
        name: 'Game code',
        category1: 'Game',
        category2: 'Online Game Items',
        itemType: Iyzipay::Model::BasketItemType::VIRTUAL,
        price: '0.5',
        subMerchantKey: sub_merchant['subMerchantKey'],
        subMerchantPrice: '0.42'
    }
    item3 = {
        id: 'BI103',
        name: 'Usb',
        category1: 'Electronics',
        category2: 'Usb / Cable',
        itemType: Iyzipay::Model::BasketItemType::PHYSICAL,
        price: '0.2',
        subMerchantKey: sub_merchant['subMerchantKey'],
        subMerchantPrice: '0.18'
    }
    request = {
        locale: Iyzipay::Model::Locale::TR,
        conversationId: '123456789',
        price: '1',
        paidPrice: '1.1',
        currency: Iyzipay::Model::Currency::TRY,
        installment: 1,
        basketId: 'B67832',
        paymentChannel: Iyzipay::Model::PaymentChannel::WEB,
        paymentGroup: Iyzipay::Model::PaymentGroup::PRODUCT,
        paymentCard: payment_card,
        buyer: buyer,
        billingAddress: address,
        shippingAddress: address,
        basketItems: [item1, item2, item3]
    }
    payment = Iyzipay::Model::Payment.new.create(request, @options)
    begin
      $stdout.puts payment.inspect
      payment = JSON.parse(payment)
      expect(payment['status']).to eq('success')
      expect(payment['locale']).to eq('tr')
      expect(payment['systemTime']).not_to be_nil
      expect(payment['conversationId']).to eq('123456789')
      expect(payment['price']).to eq(1)
      expect(payment['paidPrice']).to eq(1.1)
      expect(payment['installment']).to eq(1)
    rescue
      $stderr.puts 'oops'
      raise
    end
  end

  it 'should create payment with registered card' do
    # create card
    card = Builder::CardBuilder.new.create_card(@options)

    payment_card = {
        cardUserKey: card['cardUserKey'],
        cardToken: card['cardToken']
    }
    buyer = {
        id: 'BY789',
        name: 'John',
        surname: 'Doe',
        gsmNumber: '+905350000000',
        email: 'email@email.com',
        identityNumber: '74300864791',
        lastLoginDate: '2015-10-05 12:43:35',
        registrationDate: '2013-04-21 15:12:09',
        registrationAddress: 'Nidakule Göztepe, Merdivenköy Mah. Bora Sok. No:1',
        ip: '85.34.78.112',
        city: 'Istanbul',
        country: 'Turkey',
        zipCode: '34732'
    }
    address = {
        contactName: 'Jane Doe',
        city: 'Istanbul',
        country: 'Turkey',
        address: 'Nidakule Göztepe, Merdivenköy Mah. Bora Sok. No:1',
        zipCode: '34732'
    }

    item1 = {
        id: 'BI101',
        name: 'Binocular',
        category1: 'Collectibles',
        category2: 'Accessories',
        itemType: Iyzipay::Model::BasketItemType::PHYSICAL,
        price: '0.3'
    }
    item2 = {
        id: 'BI102',
        name: 'Game code',
        category1: 'Game',
        category2: 'Online Game Items',
        itemType: Iyzipay::Model::BasketItemType::VIRTUAL,
        price: '0.5'
    }
    item3 = {
        id: 'BI103',
        name: 'Usb',
        category1: 'Electronics',
        category2: 'Usb / Cable',
        itemType: Iyzipay::Model::BasketItemType::PHYSICAL,
        price: '0.2'
    }
    request = {
        locale: Iyzipay::Model::Locale::TR,
        conversationId: '123456789',
        price: '1',
        paidPrice: '1.1',
        currency: Iyzipay::Model::Currency::TRY,
        installment: 1,
        basketId: 'B67832',
        paymentChannel: Iyzipay::Model::PaymentChannel::WEB,
        paymentGroup: Iyzipay::Model::PaymentGroup::LISTING,
        paymentCard: payment_card,
        buyer: buyer,
        billingAddress: address,
        shippingAddress: address,
        basketItems: [item1, item2, item3]
    }
    payment = Iyzipay::Model::Payment.new.create(request, @options)
    begin
      $stdout.puts payment.inspect
      payment = JSON.parse(payment)
      expect(payment['status']).to eq('success')
      expect(payment['locale']).to eq('tr')
      expect(payment['systemTime']).not_to be_nil
      expect(payment['conversationId']).to eq('123456789')
      expect(payment['price']).to eq(1)
      expect(payment['paidPrice']).to eq(1.1)
      expect(payment['installment']).to eq(1)
    rescue
      $stderr.puts 'oops'
      raise
    end
  end

  it 'should retrieve payment' do
    # create payment
    payment = Builder::PaymentBuilder.new.create_standard_listing_payment(@options)

    request = {
        locale: Iyzipay::Model::Locale::TR,
        conversationId: '123456789',
        paymentId: payment['paymentId'],
        paymentConversationId: '123456789'
    }

    retrieved_payment = Iyzipay::Model::Payment.new.retrieve(request, @options)
    begin
      $stdout.puts retrieved_payment.inspect
      retrieved_payment = JSON.parse(retrieved_payment)
      expect(retrieved_payment['status']).to eq('success')
      expect(retrieved_payment['locale']).to eq('tr')
      expect(retrieved_payment['systemTime']).not_to be_nil
      expect(retrieved_payment['conversationId']).to eq('123456789')
      expect(retrieved_payment['price']).to eq(1)
      expect(retrieved_payment['paidPrice']).to eq(1.1)
      expect(retrieved_payment['installment']).to eq(1)
      expect(retrieved_payment['paymentId']).to eq(payment['paymentId'])
    rescue
      $stderr.puts 'oops'
      raise
    end
  end

  after :each do
  end
end