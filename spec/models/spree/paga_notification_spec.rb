require 'spec_helper'

describe Spree::PagaNotification do
  it { should validate_presence_of(:transaction_id)}
  it { should validate_presence_of(:amount)}
  it { should validate_uniqueness_of(:transaction_id)}


  describe 'check_transaction_status' do
    before do
      @paga_notification = Spree::PagaNotification.new
      @paga_notification.transaction_id = 1
      @paga_notification.amount = 100
      @paga_notification.save!
    end

    context 'when transaction not present' do

      it "transaction should not be successful" do
        Spree::PagaTransaction.where(:transaction_id => @paga_notification.transaction_id).first.should be_nil 
      end
    end

    context 'when transaction present' do
      before do
        @order = Spree::Order.create!
      end

      context 'when amount is valid' do
        before do
          @paga_transaction = Spree::PagaTransaction.new(:amount => 100)
          @paga_transaction.order = @order
          @paga_transaction.transaction_id = @paga_notification.transaction_id
          @paga_transaction.save!
        end

        it "should be successful" do
          @paga_transaction.reload.should be_success
        end

        it "should have same amount as notification" do
          @paga_transaction.reload.amount.should eq(@paga_notification.amount)
        end
      end

      context 'when amount is not valid' do
        before do
          @paga_transaction = Spree::PagaTransaction.new(:amount => -50)
          @paga_transaction.order = @order
          @paga_transaction.transaction_id = @paga_notification.transaction_id
          @paga_transaction.save(:validate => false)
        end
        it "transaction should not be successful" do
          @paga_transaction.should_not be_success
        end
      end
    end
  end
end