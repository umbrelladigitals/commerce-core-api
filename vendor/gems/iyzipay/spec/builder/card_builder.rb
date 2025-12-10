# coding: utf-8

require_relative '../spec_helper'

module Builder
  class CardBuilder

    def create_card(options)
      card_information = {
          cardAlias: 'card alias',
          cardHolderName: 'John Doe',
          cardNumber: '5528790000000008',
          expireYear: '2030',
          expireMonth: '12'
      }
      request = {
          locale: Iyzipay::Model::Locale::TR,
          conversationId: '123456789',
          email: 'email@email.com',
          externalId: 'external id',
          card: card_information
      }
      card = Iyzipay::Model::Card.new.create(request, options)
      JSON.parse(card)
    end
  end
end
