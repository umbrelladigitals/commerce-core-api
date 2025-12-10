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

  it 'should create user and add card' do
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
    card = Iyzipay::Model::Card.new.create(request, @options)
    begin
      $stdout.puts card.inspect
      card = JSON.parse(card)
      expect(card['status']).to eq('success')
      expect(card['locale']).to eq('tr')
      expect(card['systemTime']).not_to be_nil
      expect(card['conversationId']).to eq('123456789')
      expect(card['externalId']).to eq('external id')
      expect(card['email']).to eq('email@email.com')
      expect(card['cardUserKey']).to eq(card['cardUserKey'])
      expect(card['cardToken']).to eq(card['cardToken'])
      expect(card['cardAlias']).to eq('card alias')
      expect(card['binNumber']).to eq('552879')
      expect(card['cardType']).to eq('CREDIT_CARD')
      expect(card['cardAssociation']).to eq('MASTER_CARD')
      expect(card['cardFamily']).to eq('Paraf')
      expect(card['cardBankCode']).to eq(12)
      expect(card['cardBankName']).to eq('Halk Bankası')
    rescue
      $stderr.puts 'oops'
      raise
    end
  end

  it 'should create card and add card to existing user' do
    # create card user
    card = Builder::CardBuilder.new.create_card(@options)

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
        cardUserKey: card['cardUserKey'],
        card: card_information
    }
    card = Iyzipay::Model::Card.new.create(request, @options)
    begin
      $stdout.puts card.inspect
      card = JSON.parse(card)
      expect(card['status']).to eq('success')
      expect(card['locale']).to eq('tr')
      expect(card['systemTime']).not_to be_nil
      expect(card['conversationId']).to eq('123456789')
      expect(card['email']).to eq('email@email.com')
      expect(card['cardUserKey']).to eq(card['cardUserKey'])
      expect(card['cardToken']).to eq(card['cardToken'])
      expect(card['cardAlias']).to eq('card alias')
      expect(card['binNumber']).to eq('552879')
      expect(card['cardType']).to eq('CREDIT_CARD')
      expect(card['cardAssociation']).to eq('MASTER_CARD')
      expect(card['cardFamily']).to eq('Paraf')
      expect(card['cardBankCode']).to eq(12)
      expect(card['cardBankName']).to eq('Halk Bankası')
    rescue
      $stderr.puts 'oops'
      raise
    end
  end

  it 'should delete card' do
    # create card
    card = Builder::CardBuilder.new.create_card(@options)

    request = {
        locale: Iyzipay::Model::Locale::TR,
        conversationId: '123456789',
        cardToken: card['cardToken'],
        cardUserKey: card['cardUserKey']
    }
    card = Iyzipay::Model::Card.new.delete(request, @options)
    begin
      $stdout.puts card.inspect
      card = JSON.parse(card)
      expect(card['status']).to eq('success')
      expect(card['locale']).to eq('tr')
      expect(card['systemTime']).not_to be_nil
      expect(card['conversationId']).to eq('123456789')
    rescue
      $stderr.puts 'oops'
      raise
    end
  end

  it 'should retrieve card' do
    card = Builder::CardBuilder.new.create_card(@options)

    request = {
        locale: Iyzipay::Model::Locale::TR,
        conversationId: '123456789',
        cardUserKey: card['cardUserKey']
    }
    card_list = Iyzipay::Model::CardList.new.retrieve(request, @options)
    begin
      $stdout.puts card_list.inspect
      card_list = JSON.parse(card_list)
      expect(card_list['status']).to eq('success')
      expect(card_list['locale']).to eq('tr')
      expect(card_list['systemTime']).not_to be_nil
      expect(card_list['conversationId']).to eq('123456789')
      expect(card_list['cardUserKey']).to eq(card['cardUserKey'])
      expect(card_list['cardDetails'][0]['cardToken']).to eq(card['cardToken'])
      expect(card_list['cardDetails'][0]['cardAlias']).to eq('card alias')
      expect(card_list['cardDetails'][0]['binNumber']).to eq('552879')
      expect(card_list['cardDetails'][0]['cardType']).to eq('CREDIT_CARD')
      expect(card_list['cardDetails'][0]['cardAssociation']).to eq('MASTER_CARD')
      expect(card_list['cardDetails'][0]['cardFamily']).to eq('Paraf')
      expect(card_list['cardDetails'][0]['cardBankCode']).to eq(12)
      expect(card_list['cardDetails'][0]['cardBankName']).to eq('Halk Bankası')
    rescue
      $stderr.puts 'oops'
      raise
    end
  end

  after :each do
  end
end