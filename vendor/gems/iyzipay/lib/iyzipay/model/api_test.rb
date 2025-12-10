module Iyzipay
  module Model
    class ApiTest < IyzipayResource

      def retrieve(options)
        HttpClient.get("#{options.base_url}/payment/test")
      end
    end
  end
end