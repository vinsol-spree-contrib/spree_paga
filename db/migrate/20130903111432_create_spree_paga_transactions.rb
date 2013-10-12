class CreateSpreePagaTransactions < ActiveRecord::Migration
  def change
    create_table :spree_paga_transactions do |t|
      t.integer :user_id
      t.integer :order_id
      t.decimal :amount, :precision => 8, :scale => 2
      t.string :status
      t.string :response_status
      t.string :transaction_id
      t.decimal :paga_fee, :precision => 8, :scale => 2
      t.string :transaction_type
      t.timestamps
    end
  end
end
