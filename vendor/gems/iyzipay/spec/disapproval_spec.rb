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

  it 'should disapprove payment item' do
    # create sub merchant
    sub_merchant = Builder::SubMerchantBuilder.new.create_personal_sub_merchant(@options)

    # create payment
    payment = Builder::PaymentBuilder.new.create_marketplace_payment(@options, sub_merchant['subMerchantKey'])

    # approve payment
    Builder::ApprovalBuilder.new.create_approval(@options, payment['itemTransactions'][0]['paymentTransactionId'])

    # disapprove payment
    request = {
        locale: Iyzipay::Model::Locale::TR,
        conversationId: '123456789',
        paymentTransactionId: payment['itemTransactions'][0]['paymentTransactionId']
    }
    disapproval = Iyzipay::Model::Disapproval.new.create(request, @options)
    begin
      $stdout.puts disapproval.inspect
      disapproval = JSON.parse(disapproval)
      expect(disapproval['status']).to eq('success')
      expect(disapproval['locale']).to eq('tr')
      expect(disapproval['systemTime']).not_to be_nil
      expect(disapproval['conversationId']).to eq('123456789')
      expect(disapproval['paymentTransactionId']).to eq(payment['itemTransactions'][0]['paymentTransactionId'])
    rescue
      $stderr.puts 'oops'
      raise
    end
  end

  after :each do
  end
end