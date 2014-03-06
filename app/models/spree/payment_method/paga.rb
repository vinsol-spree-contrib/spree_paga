module Spree
  class PaymentMethod::Paga < PaymentMethod

    preference :private_notification_key, :string
    preference :merchant_key, :string
    preference :paga_script, :string

    attr_accessible :preferred_private_notification_key, :preferred_merchant_key, :preferred_paga_script
    def actions
      %w{}
    end

    def source_required?
      false
    end
  end
end
