class Spree::PagaNotification < ActiveRecord::Base
  validates :transaction_id, :amount, :presence => true
  validates :transaction_id, :uniqueness => true

  after_save :check_transaction_status

  def self.build_with_params(params)
    transaction_response = Spree::PagaNotification.new
    transaction_response.transaction_reference = params[:transaction_reference]
    transaction_response.transaction_id = params[:transaction_id]
    transaction_response.amount = params[:amount]
    transaction_response.transaction_type = params[:transaction_type]
    transaction_response.transaction_datetime = Time.current
    transaction_response.save
    transaction_response
  end


  private

  def check_transaction_status
    paga_transaction = Spree::PagaTransaction.where(:transaction_id => self.transaction_id).first
    if paga_transaction && paga_transaction.amount_valid?
      paga_transaction.status = Spree::PagaTransaction::SUCCESSFUL
      paga_transaction.amount = self.amount
      paga_transaction.save
      order.finalize_order if (order = paga_transaction.order) && order.pending? 
    end
  end
end
