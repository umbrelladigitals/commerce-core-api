module Iyzipay
  module Model
    class Card < IyzipayResource

      def create(request = {}, options)
        pki_string = to_pki_string_create(request)
        HttpClient.post("#{options.base_url}/cardstorage/card", get_http_header(pki_string, options), request.to_json)
      end

      def delete(request = {}, options)
        pki_string = to_pki_string_delete(request)
        HttpClient.delete("#{options.base_url}/cardstorage/card", get_http_header(pki_string, options), request.to_json)
      end

      def to_pki_string_create(request)
        PkiBuilder.new.
            append(:locale, request[:locale]).
            append(:conversationId, request[:conversationId]).
            append(:externalId, request[:externalId]).
            append(:email, request[:email]).
            append(:cardUserKey, request[:cardUserKey]).
            append(:card, CardInformation.to_pki_string(request[:card])).
            get_request_string
      end

      def to_pki_string_delete(request)
        PkiBuilder.new.
            append(:locale, request[:locale]).
            append(:conversationId, request[:conversationId]).
            append(:cardUserKey, request[:cardUserKey]).
            append(:cardToken, request[:cardToken]).
            get_request_string
      end
    end
  end
end