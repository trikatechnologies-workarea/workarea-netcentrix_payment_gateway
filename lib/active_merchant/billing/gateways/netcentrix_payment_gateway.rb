require 'net/http'
require 'httparty'

module ActiveMerchant
  module Billing
    class NetcentrixPaymentGateway < CreditCard
      attr_reader :options

      SUCCESS_MESSAGE = "Netcentrix Gateway: Payment is successfully processed."
     
      def authorize(money, paysource, options = {})
        payment_info = order_info(money, paysource)
        payment_api(payment_info, money)
      end

      def void(paysource, options = {})
        Response.new(true, SUCCESS_MESSAGE, { authorization: paysource }, test: true)
      end

      def order_info(money, paysource)
        current_order = Workarea::Order.find_current
        #Changed the format of workarea credit card months from 1..9 to netcentrix needed/acceptance of 01..09 and 11, 12 will be as it is. 
        credit_card_month = format('%02d', paysource.month)

        order = {
          "OrderNumber" => "#{current_order.id}",
          "PaymentType" => 'Credit Card',
          "PaymentAmount" => "#{money.to_f/100}",
          "CardNumber" => "#{paysource.number}",
          "Token" => '',
          "CardType" => "VI",
          "CardExpMonth" => "#{credit_card_month}",
          "CardExpYear" => "#{paysource.year}",
          "CardCID" => "#{paysource.verification_value}"
        }
        return order
      end

      def headers
        {
          "Content-Type" => "text/xml"
        }
      end

      def payment_authentication
        {
          "merchant" => "#{Rails.application.secrets.netcentrix_payment_merchant rescue nil}" ,
          "password" => "#{Rails.application.secrets.netcentrix_payment_password rescue nil}" 
        }
      end

      # Method to generate XML body payload for payment API. Method argument to replace necessary xml fields.
      def payment_body(ord)

        req_body = {
          "Authentication" => {
            "Merchant" => payment_authentication['merchant'],
            "Password" => payment_authentication['password']
          },
          "Action" => "PUSHPAYMENT",
          "Payments" => {
            "Payment" => ord
          }
        }
        xml_req = req_body.to_xml(:root => 'DATASTART', skip_types: true)
      end

      # API call to push payment related information to the ecometry via netcentrix APIs. In order to successfully hit the API please pass payment related information in the method argument which is in Hash structure.
      def payment_api(order, money)
        body = payment_body(order)
        endpoint = Rails.application.secrets.netcentrix_api rescue nil
        response = HTTParty.post(endpoint, :headers => headers, :body => body)
        hsh = Hash.from_xml(response.parsed_response)

        if hsh['Pushpayment']['Success'] == 'Y'
          puts "Payment is successfully processed."
          Response.new(
            success_from(response),
            SUCCESS_MESSAGE,
            {authorized_amount: money},
            authorization: authorization_from(response),
          )
        else
          response = false
          puts "Bad Request please validate information."
        end
      end

      private

      def success_from(response)
        response.code == 200
      end

      def authorization_from(response)
        response.object_id.to_s
      end
    end
  end
end
