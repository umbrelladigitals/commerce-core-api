# coding: utf-8

require_relative '../spec_helper'

module Builder
  class SubMerchantBuilder

    def create_personal_sub_merchant(options)
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
          identityNumber: random_number,
          currency: Iyzipay::Model::Currency::TRY
      }
      sub_merchant = Iyzipay::Model::SubMerchant.new.create(request, options)
      JSON.parse(sub_merchant)
    end

    def create_private_sub_merchant(options)
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
      sub_merchant = Iyzipay::Model::SubMerchant.new.create(request, options)
      JSON.parse(sub_merchant)
    end

    def create_limited_sub_merchant(options)
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
      sub_merchant = Iyzipay::Model::SubMerchant.new.create(request, options)
      JSON.parse(sub_merchant)
    end

    def create_limited_sub_merchant_with_external_key(external_key, options)
      request = {
          locale: Iyzipay::Model::Locale::TR,
          conversationId: '123456789',
          subMerchantExternalId: external_key,
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
      sub_merchant = Iyzipay::Model::SubMerchant.new.create(request, options)
      JSON.parse(sub_merchant)
    end
  end
end
