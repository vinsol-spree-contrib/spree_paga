module Spree
  class PaymentMethod::Paga < PaymentMethod

    preference :private_notification_key, :string
    preference :merchant_key, :string
    preference :paga_script, :string

    def actions
      %w{}
    end

    def source_required?
      false
    end
  end
end
