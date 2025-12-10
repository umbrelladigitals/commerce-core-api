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

  it 'should create personal sub merchant' do
    random_number = Random.rand(11**11).to_s
    request = {
        locale: Iyzipay::Model::Locale::TR,
        conversationId: '123456789',
        subMerchantExternalId: 'B' + random_number,
        subMerchantType: Iyzipay::Model::SubMerchantType::PERSONAL,
        address: 'Nidakule Göztepe, Merdivenköy Mah. Bora Sok. No:1',
        contactName: 'John',
        contactSurname: 'Doe',
        email: random_number + '@email.com',
        gsmNumber: '+905350000000',
        name: 'John\'s market',
        iban: 'TR180006200119000006672315',
        identityNumber: '1234567890',
        currency: Iyzipay::Model::Currency::TRY
    }
    sub_merchant = Iyzipay::Model::SubMerchant.new.create(request, @options)
    begin
      $stdout.puts sub_merchant.inspect
      sub_merchant = JSON.parse(sub_merchant)
      expect(sub_merchant['status']).to eq('success')
      expect(sub_merchant['locale']).to eq('tr')
      expect(sub_merchant['systemTime']).not_to be_nil
      expect(sub_merchant['conversationId']).to eq('123456789')
    rescue
      $stderr.puts 'oops'
      raise
    end
  end

  it 'should create private sub merchant' do
    random_number = Random.rand(11**11).to_s
    request = {
        locale: Iyzipay::Model::Locale::TR,
        conversationId: '123456789',
        subMerchantExternalId: 'B' + random_number,
        subMerchantType: Iyzipay::Model::SubMerchantType::PRIVATE_COMPANY,
        address: 'Nidakule Göztepe, Merdivenköy Mah. Bora Sok. No:1',
        taxOffice: 'Tax office',
        legalCompanyTitle: 'John Doe inc',
        email: random_number + '@email.com',
        gsmNumber: '+905350000000',
        name: 'John\'s market',
        iban: 'TR180006200119000006672315',
        identityNumber: '31300864726',
        currency: Iyzipay::Model::Currency::TRY
    }
    sub_merchant = Iyzipay::Model::SubMerchant.new.create(request, @options)
    begin
      sub_merchant = JSON.parse(sub_merchant)
      expect(sub_merchant['status']).to eq('success')
      expect(sub_merchant['locale']).to eq('tr')
      expect(sub_merchant['systemTime']).not_to be_nil
      expect(sub_merchant['conversationId']).to eq('123456789')
    rescue
      $stderr.puts 'oops'
      raise
    end
  end

  it 'should create limited company sub merchant' do
    random_number = Random.rand(11**11).to_s
    request = {
        locale: Iyzipay::Model::Locale::TR,
        conversationId: '123456789',
        subMerchantExternalId: 'B' + random_number,
        subMerchantType: Iyzipay::Model::SubMerchantType::LIMITED_OR_JOINT_STOCK_COMPANY,
        address: 'Nidakule Göztepe, Merdivenköy Mah. Bora Sok. No:1',
        taxOffice: 'Tax office',
        taxNumber: '9261877',
        legalCompanyTitle: 'XYZ inc',
        email: 'email@submerchantemail.com',
        gsmNumber: '+905350000000',
        name: 'John\'s market',
        iban: 'TR180006200119000006672315',
        currency: Iyzipay::Model::Currency::TRY
    }
    sub_merchant = Iyzipay::Model::SubMerchant.new.create(request, @options)
    begin
      sub_merchant = JSON.parse(sub_merchant)
      expect(sub_merchant['status']).to eq('success')
      expect(sub_merchant['locale']).to eq('tr')
      expect(sub_merchant['systemTime']).not_to be_nil
      expect(sub_merchant['conversationId']).to eq('123456789')
    rescue
      $stderr.puts 'oops'
      raise
    end
  end

  it 'should update personal sub merchant' do
    # create personal sub merchant
    sub_merchant = Builder::SubMerchantBuilder.new.create_personal_sub_merchant(@options)

    request = {
        locale: Iyzipay::Model::Locale::TR,
        conversationId: '123456789',
        subMerchantExternalId: sub_merchant['subMerchantExternalId'],
        subMerchantKey: sub_merchant['subMerchantKey'],
        iban: 'TR180006200119000006672315',
        address: 'Nidakule Göztepe, Merdivenköy Mah. Bora Sok. No:1',
        contactName: 'Jane',
        contactSurname: 'Doe',
        email: 'email@submerchantemail.com',
        gsmNumber: '+905350000000',
        name: 'Jane\'s market',
        identityNumber: '31300864726',
        currency: Iyzipay::Model::Currency::TRY
    }
    sub_merchant = Iyzipay::Model::SubMerchant.new.update(request, @options)
    begin
      $stdout.puts sub_merchant.inspect
      sub_merchant = JSON.parse(sub_merchant)
      expect(sub_merchant['status']).to eq('success')
      expect(sub_merchant['locale']).to eq('tr')
      expect(sub_merchant['systemTime']).not_to be_nil
      expect(sub_merchant['conversationId']).to eq('123456789')
    rescue
      $stderr.puts 'oops'
      raise
    end
  end

  it 'should update private sub merchant' do
    # create private sub merchant
    sub_merchant = Builder::SubMerchantBuilder.new.create_private_sub_merchant(@options)

    request = {
        locale: Iyzipay::Model::Locale::TR,
        conversationId: '123456789',
        subMerchantExternalId: 'S49222',
        subMerchantKey: sub_merchant['subMerchantKey'],
        address: 'Nidakule Göztepe, Merdivenköy Mah. Bora Sok. No:1',
        taxOffice: 'Tax office',
        legalCompanyTitle: 'Jane Doe inc',
        email: 'email@submerchantemail.com',
        gsmNumber: '+905350000000',
        name: 'Jane\'s market',
        iban: 'TR180006200119000006672315',
        identityNumber: '31300864726',
        currency: Iyzipay::Model::Currency::TRY
    }
    sub_merchant = Iyzipay::Model::SubMerchant.new.update(request, @options)
    begin
      $stdout.puts sub_merchant.inspect
      sub_merchant = JSON.parse(sub_merchant)
      expect(sub_merchant['status']).to eq('success')
      expect(sub_merchant['locale']).to eq('tr')
      expect(sub_merchant['systemTime']).not_to be_nil
      expect(sub_merchant['conversationId']).to eq('123456789')
    rescue
      $stderr.puts 'oops'
      raise
    end
  end

  it 'should update limited company sub merchant' do
    sub_merchant = Builder::SubMerchantBuilder.new.create_limited_sub_merchant(@options)

    request = {
        locale: Iyzipay::Model::Locale::TR,
        conversationId: '123456789',
        subMerchantKey: sub_merchant['subMerchantKey'],
        address: 'Nidakule Göztepe, Merdivenköy Mah. Bora Sok. No:1',
        taxOffice: 'Tax office',
        taxNumber: '9261877',
        legalCompanyTitle: 'ABC inc',
        email: 'email@submerchantemail.com',
        gsmNumber: '+905350000000',
        name: 'Jane\'s market',
        iban: 'TR180006200119000006672315',
        currency: Iyzipay::Model::Currency::TRY
    }
    sub_merchant = Iyzipay::Model::SubMerchant.new.update(request, @options)
    begin
      $stdout.puts sub_merchant.inspect
      sub_merchant = JSON.parse(sub_merchant)
      expect(sub_merchant['status']).to eq('success')
      expect(sub_merchant['locale']).to eq('tr')
      expect(sub_merchant['systemTime']).not_to be_nil
      expect(sub_merchant['conversationId']).to eq('123456789')
    rescue
      $stderr.puts 'oops'
      raise
    end
  end

  it 'should retrieve sub merchant' do
    random_number = Random.rand(11**11).to_s
    Builder::SubMerchantBuilder.new.create_limited_sub_merchant_with_external_key(random_number, @options)

    request = {
        locale: Iyzipay::Model::Locale::TR,
        conversationId: '123456789',
        subMerchantExternalId: random_number
    }
    sub_merchant = Iyzipay::Model::SubMerchant.new.retrieve(request, @options)
    begin
      $stdout.puts sub_merchant.inspect
      sub_merchant = JSON.parse(sub_merchant)
      expect(sub_merchant['status']).to eq('success')
      expect(sub_merchant['locale']).to eq('tr')
      expect(sub_merchant['systemTime']).not_to be_nil
      expect(sub_merchant['conversationId']).to eq('123456789')
    rescue
      $stderr.puts 'oops'
      raise
    end
  end

  after :each do
  end
end