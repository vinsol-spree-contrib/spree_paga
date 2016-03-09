class Spree::PagaTransaction < ActiveRecord::Base
  MINIMUM_AMT = 1
  PENDING      = 'Pending'
  SUCCESSFUL  = 'Successful'
  UNSUCCESSFUL = 'Unsuccessful'

  belongs_to :order
  belongs_to :user
  validates :amount, numericality: { greater_than_or_equal_to: MINIMUM_AMT }
  validates :transaction_id, :order, presence: true, if: :response_status?
  validates :transaction_id, uniqueness: true, allow_blank: true

  before_validation :assign_values, on: :create
  before_save :update_transaction_status, unless: :success?
  before_save :update_payment_source, if: :transaction_id_changed?
  before_save :finalize_order, if: [:success?, :status_changed?]
  before_update :set_pending_for_payment, if: [:status_changed?, :pending?]
  before_save :order_set_failure_for_payment, if: [:status_changed?, :unsuccessful?]
  delegate :currency, to: :order

  def assign_values
    self.status = PENDING
    self.amount = order.remaining_total
  end

  def success?
    status == SUCCESSFUL
  end

  def unsuccessful?
    status == UNSUCCESSFUL
  end

  def pending?
    status == PENDING
  end

  def amount_valid?
    amount >= order.remaining_total
  end

  def update_transaction(transaction_params)
    self.transaction_id = transaction_params[:transaction_id].present? ? transaction_params[:transaction_id] : generate_transaction_id
    self.paga_fee = transaction_params[:fee]
    self.amount = transaction_params[:total]
    self.response_status = transaction_params[:status]
    self.save
  end

  def generate_transaction_id
    begin
      self.transaction_id = SecureRandom.hex(10)
    end while Spree::PagaTransaction.exists?(transaction_id: transaction_id)
    transaction_id
  end

  private

  def set_pending_for_payment
    payment = order.paga_payment
    payment.pend!
  end

  def order_set_failure_for_payment
    payment = order.paga_payment
    payment.failure!
  end

  def finalize_order
    order.finalize_order
  end

  def update_payment_source
    payment = order.paga_payment
    payment.source = Spree::PaymentMethod::Paga.first
    payment.save
    payment.started_processing!
  end

  def update_transaction_status
    paga_notification = Spree::PagaNotification.find_by(transaction_id: self.transaction_id)
    if paga_notification && amount_valid?
      self.status = SUCCESSFUL
      self.amount = paga_notification.amount
    end
    true
  end
end
