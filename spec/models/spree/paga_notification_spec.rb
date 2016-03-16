require 'spec_helper'

describe Spree::PagaNotification do
  it { is_expected.to validate_presence_of(:transaction_id)}
  it { is_expected.to validate_presence_of(:amount)}
  it { is_expected.to validate_uniqueness_of(:transaction_id)}


  describe 'update_transaction_status' do
    before do
      @paga_notification = Spree::PagaNotification.new
      @paga_notification.transaction_id = 1
      @paga_notification.amount = 100
      @paga_notification.save!
    end

    context 'when transaction not present' do

      it "transaction should not be successful" do
        expect(Spree::PagaTransaction.find_by(transaction_id: @paga_notification.transaction_id)).to be_nil
      end
    end

    context 'when transaction present' do
      before do
        @order = Spree::Order.create!
      end

      context 'when amount is valid' do
        before do
          @order.update_column(:total, 100)
          @paga_transaction = @order.paga_transactions.new(transaction_id: 1)
          allow(@paga_transaction).to receive(:update_payment_source).and_return(true)
          allow(@paga_transaction).to receive(:finalize_order).and_return(true)
          @paga_transaction.save!
        end

        it "should be successful" do
          expect(@paga_transaction.reload).to be_success
        end

        it "should have same amount as notification" do
          expect(@paga_transaction.reload.amount).to eq(@paga_notification.amount)
        end
      end

      context 'when amount is not valid' do
        before do
          @order.update_column(:total, 100)
          @paga_transaction = @order.paga_transactions.new(transaction_id: 1)
          allow(@paga_transaction).to receive(:update_payment_source).and_return(true)
          allow(@paga_transaction).to receive(:finalize_order).and_return(true)
          allow(@paga_transaction).to receive(:update_transaction_status).and_return(true)
          @paga_transaction.save(validate: false)
          @paga_transaction.amount = 0
          @paga_transaction.save(validate: false)
        end
        it "transaction should not be successful" do
          expect(@paga_transaction).not_to be_success
        end
      end
    end
  end


  describe '.build_with_params' do
    it "should save attributes of notification" do
      notification = Spree::PagaNotification.save_with_params({transaction_reference: "123", amount: 100.0, transaction_type: "paga", transaction_datetime: Time.current, transaction_id: "trans123"})
      expect(notification.transaction_reference).to  eq("123")
      expect(notification.transaction_id).to  eq("trans123")
      expect(notification.amount).to  eq(100.0)
      expect(notification.transaction_type).to  eq("paga")
    end
  end
end
