# coding: utf-8

require_relative '../spec_helper'

module Builder
  class CheckoutFormBuilder

    def create_checkout_form_initialize(options)
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
          paidPrice: '1.2',
          currency: Iyzipay::Model::Currency::TRY,
          basketId: 'B67832',
          paymentGroup: Iyzipay::Model::PaymentGroup::LISTING,
          callbackUrl: 'https://www.merchant.com/callback',
          enabledInstallments: [2, 3, 6, 9],
          buyer: buyer,
          billingAddress: address,
          shippingAddress: address,
          basketItems: [item1, item2, item3]
      }
      checkout_form_initialize = Iyzipay::Model::CheckoutFormInitialize.new.create(request, options)
      JSON.parse(checkout_form_initialize)
    end
  end
end
