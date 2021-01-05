
module ActiveMerchant
  module Billing
    class NetcentrixPaymentGateway < CreditCard
      attr_reader :options

      AUTHORIZATION = '53433'
      SUCCESS_MESSAGE = 'Netcentrix Gateway: Forced success'
     
      def authorize(money, paysource, options = {})
        payment_info = order_info(money, paysource)
        Workarea::Netcentrix::NetcentrixGateway.new.payment_api(payment_info)
      end

      def void(paysource, options = {})
        Response.new(true, SUCCESS_MESSAGE, { authorization: paysource }, test: true)
      end

      def order_info(money, paysource)
        current_order = Workarea::Order.find_current
        order = {
          "OrderNumber" => "#{current_order.id}",
          "PaymentType" => 'Credit Card',
          "PaymentAmount" => "#{money.to_f/100}",
          "CardNumber" => "#{paysource.number}",
          "Token" => '',
          "CardType" => "VI",
          "CardExpMonth" => "#{paysource.month}",
          "CardExpYear" => "#{paysource.year}",
          "CardCID" => "#{paysource.verification_value}"
        }
        return order
      end
    end
  end
end
