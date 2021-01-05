require 'workarea'
require "workarea/netcentrix_payment_gateway/engine"
require "workarea/netcentrix_payment_gateway/version"
require 'netcentrix/gateway'

module Workarea
  module NetcentrixPaymentGateway
    # Your code goes here...
    def self.credentials
      return {} unless Rails.application.secrets.netcentrix_payment_gateway.present?
      Rails.application.secrets.netcentrix_payment_gateway.symbolize_keys
    end

    # Conditionally use the real gateway when secrets are present.
    # Otherwise, use the bogus gateway.
    #
    # @return [ActiveMerchant::Billing::Gateway]
    def self.gateway
      Workarea.config.gateways.credit_card
    end

    def self.gateway=(gateway)
      Workarea.config.gateways.credit_card = gateway
    end

    def self.auto_initialize_gateway
      if credentials.present?
        if Rails.env.test?
          self.gateway = ActiveMerchant::Billing::BogusGateway.new
        else
          byebug
          self.gateway = ActiveMerchant::Billing::NetcentrixPaymentGateway.new credentials
        end
      else
        self.gateway = ActiveMerchant::Billing::BogusGateway.new
      end
    end
  end
end
