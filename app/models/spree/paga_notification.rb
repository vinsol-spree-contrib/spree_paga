class Spree::PagaNotification < ActiveRecord::Base
  validates :transaction_id, :amount, presence: true
  validates :transaction_id, uniqueness: true, allow_blank: true

  after_save :update_transaction_status

  def self.save_with_params(notification_params)
    transaction_response = Spree::PagaNotification.new
    transaction_response.transaction_reference = notification_params[:transaction_reference]
    transaction_response.transaction_id = notification_params[:transaction_id]
    transaction_response.amount = notification_params[:amount]
    transaction_response.transaction_type = notification_params[:transaction_type]
    transaction_response.transaction_datetime = notification_params[:transaction_datetime].to_datetime
    transaction_response.save
    transaction_response
  end


  private

  def update_transaction_status
    paga_transaction = Spree::PagaTransaction.find_by(transaction_id: self.transaction_id)
    if paga_transaction && paga_transaction.amount_valid?
      paga_transaction.status = Spree::PagaTransaction::SUCCESSFUL
      paga_transaction.amount = self.amount
      paga_transaction.save
    end
  end
end
