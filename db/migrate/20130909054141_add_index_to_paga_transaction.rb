class AddIndexToPagaTransaction < ActiveRecord::Migration
  def change
    add_index "spree_paga_transactions", "transaction_id", :name => "index_spree_paga_transaction_on_transaction_id", :unique => true
  end
end
