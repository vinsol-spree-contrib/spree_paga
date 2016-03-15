Spree::Order.class_eval do

  has_many :paga_transactions

  def paga_payment
    @paga_payment_method = Spree::PaymentMethod::Paga.first
    payments.where("payment_method_id = #{@paga_payment_method.id} and state in ('checkout', 'pending', 'processing')").first if @paga_payment_method
  end

  scope :not_pending, -> { where.not(state: "pending") }

  state_machine do
    event :pending do
      transition to: :pending, from: :payment
    end
  end

#### override this if partial payment is allowed as needed.
  def remaining_total
    total
  end

  def payment_or_complete_or_pending?
    payment? || complete? || pending?
  end


  def finalize_order
    paga_payment.complete!
    update_attributes(state: "complete", completed_at: Time.current)
    finalize!
    update!
  end
end
