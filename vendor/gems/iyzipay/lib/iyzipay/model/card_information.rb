module Iyzipay
  module Model
    class CardInformation
      def self.to_pki_string(request)
        unless request.nil?
          PkiBuilder.new.
              append(:cardAlias, request[:cardAlias]).
              append(:cardNumber, request[:cardNumber]).
              append(:expireYear, request[:expireYear]).
              append(:expireMonth, request[:expireMonth]).
              append(:cardHolderName, request[:cardHolderName]).
              get_request_string
        end
      end
    end
  end
end
