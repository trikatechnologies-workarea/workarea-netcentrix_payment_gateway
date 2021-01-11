require 'workarea'
require "workarea/netcentrix_payment_gateway/engine"
require "workarea/netcentrix_payment_gateway/version"
require 'active_merchant/billing/gateways/netcentrix_payment_gateway'

module Workarea
  module NetcentrixPaymentGateway

    def self.auto_initialize_gateway
      unless Rails.env.test?
        Workarea.config.gateways.credit_card = ActiveMerchant::Billing::NetcentrixPaymentGateway.new
      end
    end
  end
end
