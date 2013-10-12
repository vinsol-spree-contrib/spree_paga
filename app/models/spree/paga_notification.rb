class Spree::PagaNotification < ActiveRecord::Base
  validates :transaction_id, :amount, :presence => true
  validates :transaction_id, :uniqueness => true

  after_save :check_transaction_status

  private

  def check_transaction_status
    paga_transaction = Spree::PagaTransaction.where(:transaction_id => self.transaction_id).first
    if paga_transaction && paga_transaction.amount_valid?
      paga_transaction.status = Spree::PagaTransaction::SUCCESSFUL
      paga_transaction.amount = self.amount
      paga_transaction.save!
      order.finalize_order if (order = paga_transaction.order) && order.pending? 
    end
  end
end
