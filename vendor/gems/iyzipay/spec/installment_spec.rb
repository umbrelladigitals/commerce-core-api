# coding: utf-8

require_relative 'spec_helper'

RSpec.describe 'Iyzipay' do
  before :all do
    @options = Iyzipay::Options.new
    @options.api_key = SpecOptions::API_KEY
    @options.secret_key = SpecOptions::SECRET_KEY
    @options.base_url = SpecOptions::BASE_URL
  end

  it 'should retrieve installment' do
    request = {
        locale: Iyzipay::Model::Locale::TR,
        conversationId: '123456789',
        binNumber: '554960',
        price: '100'
    }
    installment_info = Iyzipay::Model::InstallmentInfo.new.retrieve(request, @options)
    installment_info = JSON.parse(installment_info)
    expect(installment_info['status']).to eq('success')
    expect(installment_info['locale']).to eq('tr')
    expect(installment_info['systemTime']).not_to be_nil
    expect(installment_info['conversationId']).to eq('123456789')
    expect(installment_info['installmentDetails']).not_to be_nil
    expect(installment_info['installmentDetails'][0]['binNumber']).to eq('554960')
    expect(installment_info['installmentDetails'][0]['price']).to eq(100)
    expect(installment_info['installmentDetails'][0]['cardType']).to eq('CREDIT_CARD')
    expect(installment_info['installmentDetails'][0]['cardAssociation']).to eq('MASTER_CARD')
    expect(installment_info['installmentDetails'][0]['cardFamilyName']).to eq('Bonus')
    expect(installment_info['installmentDetails'][0]['installmentPrices']).not_to be_nil
    expect(installment_info['installmentDetails'][0]['installmentPrices'][0]['installmentPrice']).not_to be_nil
    expect(installment_info['installmentDetails'][0]['installmentPrices'][0]['totalPrice']).not_to be_nil
    expect(installment_info['installmentDetails'][0]['installmentPrices'][0]['installmentNumber']).not_to be_nil
    begin
      $stdout.puts installment_info.inspect
    rescue
      $stderr.puts 'oops'
      raise
    end
  end

  after :each do
  end
end
