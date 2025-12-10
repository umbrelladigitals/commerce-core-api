# coding: utf-8

require_relative '../spec_helper'

module Builder
  class PeccoInitializeBuilder

    def create_pecco_initialize(options)
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
      pecco_initialize = Iyzipay::Model::PeccoInitialize.new.create(request, options)
      JSON.parse(pecco_initialize)
    end
  end
end
