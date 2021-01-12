Workarea::NetcentrixPaymentGateway.auto_initialize_gateway

Workarea.configure do |config|
	config.netcentrix_payment_merchant = "#{Rails.application.secrets.netcentrix_payment_merchant rescue nil}"
	config.netcentrix_payment_password = "#{Rails.application.secrets.netcentrix_payment_password rescue nil}"
	config.netcentrix_api = Rails.application.secrets.netcentrix_api rescue nil
end
