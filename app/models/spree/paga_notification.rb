class Spree::PagaNotification < ActiveRecord::Base
  validates :transaction_id, :amount, :presence => true
  validates :transaction_id, :uniqueness => true, :allow_blank => true

  after_save :update_transaction_status

  def self.save_with_params(params, transaction_id)
    transaction_response = Spree::PagaNotification.new
    transaction_response.transaction_reference = params[:transaction_reference]
    transaction_response.transaction_id = transaction_id
    transaction_response.amount = params[:amount]
    transaction_response.transaction_type = params[:transaction_type]
    transaction_response.transaction_datetime = params[:transaction_datetime].to_datetime
    transaction_response.save
  end


  private

  def update_transaction_status
    paga_transaction = Spree::PagaTransaction.where(:transaction_id => self.transaction_id).first
    if paga_transaction && paga_transaction.amount_valid?
      paga_transaction.status = Spree::PagaTransaction::SUCCESSFUL
      paga_transaction.amount = self.amount
      paga_transaction.save
    end
  end
end
