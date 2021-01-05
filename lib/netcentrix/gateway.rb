
module ActiveMerchant
  module Billing
    class NetcentrixPaymentGateway < CreditCard
      attr_reader :key, :pin, :options
      class_attribute :test_rest_endpoint, :production_rest_endpoint


      def authorize(money, credit_card, options = {})
        billing_address = options[:billing_address] || options[:address]

        post = {}
        post[:ip] = options[:ip_address] if options[:ip_address].present?
        post[:name] = billing_address[:name] if billing_address.present?
        add_amount(post, money)
        add_invoice(post, options)
        add_address_for_type(:billing, post, credit_card, billing_address) if billing_address
        if credit_card.is_a? String
          add_token(post, credit_card)
        else
          add_payment(post, credit_card)
          add_address(post, credit_card, options)
          unless credit_card.track_data.present?
            add_customer_data(post, options)
          end
        end

        add_split_payments(post, options)
        add_recurring_fields(post, options)
        add_custom_fields(post, options)
        add_line_items(post, options)
        add_test_mode(post, options)
        add_save_card(post, options)
        commit(:authorization, post)
      end

      def add_save_card(post, options)
        post[:saveCard] = (options[:save_card] ? 1 : 0) if options.has_key?(:save_card)
      end

      def parse(body)
        fields = {}
        for line in body.split('&')
          key, value = *line.scan(%r{^(\w+)\=(.*)$}).flatten
          fields[key] = CGI.unescape(value.to_s)
        end
        {
          :status           => fields['UMstatus'],
          :auth_code        => fields['UMauthCode'],
          :ref_num          => fields['UMrefNum'],
          :batch            => fields['UMbatch'],
          :avs_result       => fields['UMavsResult'],
          :avs_result_code  => fields['UMavsResultCode'],
          :cvv2_result      => fields['UMcvv2Result'],
          :cvv2_result_code => fields['UMcvv2ResultCode'],
          :vpas_result_code => fields['UMvpasResultCode'],
          :result           => fields['UMresult'],
          :error            => fields['UMerror'],
          :error_code       => fields['UMerrorcode'],
          :acs_url          => fields['UMacsurl'],
          :payload          => fields['UMpayload'],
          :token            => fields['UMcardRef']
        }.delete_if { |k, v| v.nil? }
      end

    end
  end
end
