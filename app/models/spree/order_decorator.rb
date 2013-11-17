Spree::Order.class_eval do

  has_one :paga_transaction

	def paga_payment
    @paga_payment_method = Spree::PaymentMethod::Paga.where(:environment => Rails.env).first
    payments.where("payment_method_id = #{@paga_payment_method.id} and state in ('checkout', 'pending', 'processing')").first if @paga_payment_method
  end

  scope :not_pending, -> { where('state != ?', "pending")}

  state_machine do
    event :pending do
      transition :to => :pending, :from => :payment
    end
  end

#### override this if partial payment is allowed as needed
  def remaining_total
    total
  end

  def finalize_order
    paga_payment.complete!
    update_attributes({:state => "complete", :completed_at => Time.now}, :without_protection => true)
    finalize!
  end
end