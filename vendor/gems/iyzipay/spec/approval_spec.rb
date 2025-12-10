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

  context 'when create a payment for market place and then approve payment' do
    it 'should approve payment item' do
      sub_merchant = Builder::SubMerchantBuilder.new.create_personal_sub_merchant(@options)
      payment = Builder::PaymentBuilder.new.create_marketplace_payment(@options, sub_merchant['subMerchantKey'])

      request = {
          locale: Iyzipay::Model::Locale::TR,
          conversationId: '123456789',
          paymentTransactionId: payment['itemTransactions'][0]['paymentTransactionId']
      }
      approval = Iyzipay::Model::Approval.new.create(request, @options)

      begin
        approval = JSON.parse(approval)
        expect(approval['status']).to eq('success')
        expect(approval['locale']).to eq('tr')
        expect(approval['systemTime']).not_to be_nil
        expect(approval['paymentTransactionId']).to eq(payment['itemTransactions'][0]['paymentTransactionId'])
      rescue
        $stderr.puts 'oops'
        raise
      end
    end
  end

  after :each do
  end
end