# coding: utf-8

require_relative '../spec_helper'

module Builder
  class ApprovalBuilder

    def create_approval(options, payment_transaction_id)
      request = {
          locale: Iyzipay::Model::Locale::TR,
          conversationId: '123456789',
          paymentTransactionId: payment_transaction_id
      }
      approval = Iyzipay::Model::Approval.new.create(request, options)
      JSON.parse(approval)
    end
  end
end
