module Spree
  class PaymentMethod::Paga < PaymentMethod

    preference :private_notification_key
    preference :merchant_key
    preference :paga_script
    def actions
      %w{}
    end

    # Indicates whether its possible to void the payment.
    # def can_void?(payment)
    #   payment.state != 'void'
    # end

    # def void(*args)
    #   ActiveMerchant::Billing::Response.new(true, "", {}, {})
    # end

    def source_required?
      false
    end
  end
end
