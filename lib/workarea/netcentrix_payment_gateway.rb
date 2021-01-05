require 'workarea'
require "workarea/netcentrix_payment_gateway/engine"
require "workarea/netcentrix_payment_gateway/version"
require 'active_merchant/billing/gateways/netcentrix_payment_gateway'

module Workarea
  module NetcentrixPaymentGateway

    def self.auto_initialize_gateway
      if Rails.env.test?
        Workarea.config.gateways.credit_card = ActiveMerchant::Billing::BogusGateway.new
        ActiveMerchant::Billing::Base.mode = :test
      else
        Workarea.config.gateways.credit_card = ActiveMerchant::Billing::NetcentrixPaymentGateway.new
      end
    end
  end
end
