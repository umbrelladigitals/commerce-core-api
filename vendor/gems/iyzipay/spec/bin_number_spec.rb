# coding: utf-8

require_relative 'spec_helper'

RSpec.describe 'Iyzipay' do
  before :all do
    @options = Iyzipay::Options.new
    @options.api_key = SpecOptions::API_KEY
    @options.secret_key = SpecOptions::SECRET_KEY
    @options.base_url = SpecOptions::BASE_URL
  end

  it 'should retrieve bin number' do
    request = {
        locale: Iyzipay::Model::Locale::TR,
        conversationId: '123456789',
        binNumber: '554960'
    }
    bin_number = Iyzipay::Model::BinNumber.new.retrieve(request, @options)
    begin
      #$stderr.puts bin_number.inspect
      bin_number = JSON.parse(bin_number)
      expect(bin_number['status']).to eq('success')
      expect(bin_number['locale']).to eq('tr')
      expect(bin_number['systemTime']).not_to be_nil
      expect(bin_number['conversationId']).to eq('123456789')
      expect(bin_number['binNumber']).to eq('554960')
      expect(bin_number['cardType']).to eq('CREDIT_CARD')
      expect(bin_number['cardAssociation']).to eq('MASTER_CARD')
      expect(bin_number['cardFamily']).to eq('Bonus')
      expect(bin_number['bankName']).to eq('Garanti Bankası')
      expect(bin_number['bankCode']).to eq(62)
      expect(bin_number['commercial']).to eq(0)
    rescue
      $stderr.puts 'oops'
      raise
    end
  end

  after :each do
  end
end