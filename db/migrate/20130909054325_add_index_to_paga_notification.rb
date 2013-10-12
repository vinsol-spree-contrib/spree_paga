class AddIndexToPagaNotification < ActiveRecord::Migration
  def change
    add_index "spree_paga_notifications", "transaction_id", :name => "index_spree_paga_notification_on_transaction_id", :unique => true
  end
end
