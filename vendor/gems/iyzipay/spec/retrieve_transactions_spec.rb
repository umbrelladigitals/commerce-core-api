# coding: utf-8

require_relative 'spec_helper'

RSpec.describe 'Iyzipay' do
  before :all do
    @options = Iyzipay::Options.new
    @options.api_key = SpecOptions::API_KEY
    @options.secret_key = SpecOptions::SECRET_KEY
    @options.base_url = SpecOptions::BASE_URL
  end

  it 'should retrieve payout completed transactions' do
    request = {
        locale: Iyzipay::Model::Locale::TR,
        conversationId: '123456789',
        date: '2016-01-22 19:13:00'
    }
    transaction_list = Iyzipay::Model::PayoutCompletedTransactionList.new.retrieve(request, @options)
    begin
      $stdout.puts transaction_list.inspect
      transaction_list = JSON.parse(transaction_list)
      expect(transaction_list['status']).to eq('success')
      expect(transaction_list['locale']).to eq('tr')
      expect(transaction_list['systemTime']).not_to be_nil
      expect(transaction_list['conversationId']).to eq('123456789')
    rescue
      $stderr.puts 'oops'
      raise
    end
  end

  it 'should retrieve bounced bank transfers' do
    request = {
        locale: Iyzipay::Model::Locale::TR,
        conversationId: '123456789',
        date: '2016-01-22 19:13:00'
    }
    bounced_bank_transfer_list = Iyzipay::Model::BouncedBankTransferList.new.retrieve(request, @options)
    begin
      $stdout.puts bounced_bank_transfer_list.inspect
      bounced_bank_transfer_list = JSON.parse(bounced_bank_transfer_list)
      expect(bounced_bank_transfer_list['status']).to eq('success')
      expect(bounced_bank_transfer_list['locale']).to eq('tr')
      expect(bounced_bank_transfer_list['systemTime']).not_to be_nil
      expect(bounced_bank_transfer_list['conversationId']).to eq('123456789')
    rescue
      $stderr.puts 'oops'
      raise
    end
  end

  after :each do
  end
end