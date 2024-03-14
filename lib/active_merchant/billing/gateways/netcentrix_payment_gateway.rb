require 'net/http'
require 'httparty'

module ActiveMerchant
  module Billing
    class NetcentrixPaymentGateway < CreditCard
      attr_reader :options

      SUCCESS_MESSAGE = "Netcentrix Gateway: Payment is successfully processed."
      FAILURE_MESSAGE ="Card declined. Please re-enter your payment details."
      NO_OF_TRY_OVER ='The payment has declined and Customer Service will give a call'
     
      def authorize(money, paysource, options = {})
        payment_info = order_info(money, paysource, options)
        payment_api(payment_info, money)
      end

      def void(paysource, options = {})
        Response.new(true, SUCCESS_MESSAGE, { authorization: paysource }, test: true)
      end

      def order_info(money, paysource, order_id)
        #Changed the format of workarea credit card months from 1..9 to netcentrix needed/acceptance of 01..09 and 11, 12 will be as it is. 
        credit_card_month = format('%02d', paysource.month)
        #Mapping the payment type name from workarea(Ex. visa) to netcentrix needed(Ex. VI)  
        workarea_order_id = Workarea::Order.find_by(generated_order: order_id).try(:id)
        payment = Workarea::Payment.find_by(id: workarea_order_id)
        billing_address = payment.address
        card_type = mapping_payment_type(paysource.brand).compact
        order = {
          "OrderNumber" => "#{order_id}",
          "PaymentType" => 'Credit Card',
          "PaymentAmount" => "#{money.to_f/100}",
          "CardNumber" => "#{paysource.number}",
          "Token" => '',
          "CardType" => "#{card_type.first}",
          "CardExpMonth" => "#{credit_card_month}",
          "CardExpYear" => "#{paysource.year}",
          "CardCID" => "#{paysource.verification_value}"
        }
        order.merge!('FirstName' => billing_address.first_name, 'LastName' => billing_address.last_name,
                     'Street' => billing_address.street, 'City' => billing_address.city,
                     'State' => billing_address.region, 'Zip' =>  billing_address.postal_code,
                     'Country' => billing_address.country.alpha2)
        return order
      end


      def headers
        {
          "Content-Type" => "text/xml"
        }
      end

      def payment_authentication
        {
          "merchant" => "#{Workarea.config.netcentrix_payment_merchant rescue nil}" ,
          "password" => "#{Workarea.config.netcentrix_payment_password rescue nil}" 
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
        ord = Workarea::Order.find_by(generated_order: order["OrderNumber"])
        endpoint = Workarea.config.netcentrix_api rescue nil
        ord.update_attributes(payment_request_body: body)
        response = HTTParty.post(endpoint, :headers => headers, :body => body)
        hsh = Hash.from_xml(response)
        ord.update_attributes(response_from_payment_api: response)
        if  hsh['Pushpayment']["CCAuth"] == "Approved"
          puts "Payment is successfully processed."
          ord.update_attributes(payment_error: nil)
          Response.new(
            success_from(response),
            SUCCESS_MESSAGE,
            {authorized_amount: money},
            authorization: authorization_from(response),
          )

        elsif   hsh['Pushpayment']["CCAuth"] == "Declined" && ord.payment_retry < 2
          ord.update_attributes(payment_retry: ord.payment_retry + 1, payment_error: FAILURE_MESSAGE)
          Response.new(false, FAILURE_MESSAGE, {},authorization: authorization_from(response))
        elsif hsh['Pushpayment']['Success'] == 'Y' && hsh['Pushpayment']["CCAuth"] == "Declined"
          ord.update_attributes(payment_error: NO_OF_TRY_OVER)
          Response.new(true, NO_OF_TRY_OVER, {}, authorization: authorization_from(response))
        else
          ord.update_attributes(push_to_payment_api_failed: true )
          Workarea::Storefront::PaymentMailer.notify(response.parsed_response, ord).deliver_later
          puts "Bad Request please validate information."
          response = false 
        end
      end

      private

      def success_from(response)
        response.code == 200
      end

      def authorization_from(response)
        response.object_id.to_s
      end

      def mapping_payment_type(brand)
        credit_card_type = [["visa", "VI"], ["master", "MC"], ["discover", "DI"], ["american_express", "AX"]]
        credit_card_type.map do |payment_brand|
          if payment_brand.include? brand
            payment_brand&.last
          end
        end
      end
    end
  end
end
