require 'spec_helper'

describe Spree::PagaTransaction do
  it { should allow_mass_assignment_of(:amount) }
  it { should allow_mass_assignment_of(:status) }
  it { Spree::PagaTransaction::PENDING.should eq("Pending") }
  it { Spree::PagaTransaction::SUCCESSFUL.should eq("Successful") }
  it { Spree::PagaTransaction::UNSUCCESSFUL.should eq("Unsuccessful") }

  it {should belong_to(:order)}
  it {should belong_to(:user)}

  it { should validate_numericality_of(:amount).is_greater_than_or_equal_to(Spree::PagaTransaction::MINIMUM_AMT)}
  context 'presence' do
    before { subject.stub(:response_status?) { true } }
    it { should validate_presence_of(:transaction_id)}
    it { should validate_presence_of(:order)}
  end
  it { should validate_uniqueness_of(:transaction_id)}

  describe 'methods' do
    before do
      @order = Spree::Order.create!
      @paga_transaction = Spree::PagaTransaction.new(:amount => 100)
      @paga_transaction.order = @order
      @paga_transaction.transaction_id = 1
      @paga_transaction.save
    end
    describe 'success?' do
      context 'when not succesfull' do
        it "return false if not success" do
          @paga_transaction.success?.should be_false
        end
      end

      context 'when success' do
        before do
          @paga_transaction.status = Spree::PagaTransaction::SUCCESSFUL
          @paga_transaction.save
        end

        it "return true for success" do
          @paga_transaction.success?.should be_true
        end
      end
    end

    describe 'pending?' do
      context 'when not pending' do
        it "return true if pending" do
          @paga_transaction.pending?.should be_true
        end
      end

      context 'when not pending' do
        before do
          @paga_transaction.status = Spree::PagaTransaction::SUCCESSFUL
          @paga_transaction.save
        end

        it "return false for success" do
          @paga_transaction.pending?.should be_false
        end
      end
    end

    describe 'amount_valid?' do
      context 'when amount valid' do
        before do
          @order.stub(:remaining_total).and_return(100)
          @paga_transaction.stub(:amount).and_return(100)
        end

        it "should return true" do
          @paga_transaction.amount_valid?.should be_true
        end
      end

      context 'when amount is not valid' do
        before do
          @order.stub(:remaining_total).and_return(200)
          @paga_transaction.stub(:amount).and_return(100)
        end

        it "should return false" do
          @paga_transaction.amount_valid?.should be_false
        end
      end
    end

    describe 'transaction_currency' do
      it "should give transaction_currency" do
        @paga_transaction.transaction_currency.should eq(@order.currency)
      end
    end

    describe 'check_transaction_status' do
      context 'when notification present for transaction' do
        before do
          @paga_notification = Spree::PagaNotification.new
          @paga_notification.transaction_id = @paga_transaction.transaction_id
          @paga_notification.amount = @paga_transaction.amount
          @paga_notification.save!
        end

        it "should not be succesful" do
          @paga_transaction.reload.should be_success
        end
      end

      context 'when notification absent for transaction' do
        it "should not be succesful" do
          @paga_transaction.should_not be_success
        end
      end
    end

  end

end