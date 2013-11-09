module Spree
  class PaymentMethod::Paga < PaymentMethod

    preference :private_notification_key, :string
    preference :merchant_key, :string
    preference :paga_script, :string
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
