class CreateSpreePagaNotification < ActiveRecord::Migration
  def change
    create_table :spree_paga_notifications do |t|
      t.decimal :amount, :precision => 8, :scale => 2
      t.string :transaction_id
      t.string :transaction_type
      t.string :transaction_reference
      t.datetime :transaction_datetime
      t.timestamps
    end
  end
end