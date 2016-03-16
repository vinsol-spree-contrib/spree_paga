require 'spec_helper'

describe Spree::PagaTransaction do
  before do
    allow_any_instance_of(Spree::PagaTransaction).to receive(:assign_values).and_return(true)
    allow_any_instance_of(Spree::PagaTransaction).to receive(:response_status?).and_return(true)
    allow_any_instance_of(Spree::PagaTransaction).to receive(:update_transaction_status).and_return(true)
    allow_any_instance_of(Spree::PagaTransaction).to receive(:update_payment_source).and_return(true)
    allow_any_instance_of(Spree::PagaTransaction).to receive(:finalize_order).and_return(true)
  end

  it { expect(Spree::PagaTransaction::PENDING).to eq("Pending") }
  it { expect(Spree::PagaTransaction::SUCCESSFUL).to eq("Successful") }
  it { expect(Spree::PagaTransaction::UNSUCCESSFUL).to eq("Unsuccessful") }

  it {is_expected.to belong_to(:order)}
  it {is_expected.to belong_to(:user)}

  it { is_expected.to validate_numericality_of(:amount).is_greater_than_or_equal_to(Spree::PagaTransaction::MINIMUM_AMT)}
  it { is_expected.to validate_presence_of(:transaction_id)}
  it { is_expected.to validate_presence_of(:order)}
  it { is_expected.to validate_uniqueness_of(:transaction_id)}

  describe 'methods' do
    before do
      @order = Spree::Order.create!({currency: "USD"})
      @order.update_column(:total, 100)
      @paga_transaction = Spree::PagaTransaction.new({amount: 100})
      @paga_transaction.order = @order
      @paga_transaction.transaction_id = 1
      @paga_transaction.save
    end
    describe 'success?' do
      context 'when not succesfull' do
        it "return false if not success" do
          expect(@paga_transaction.success?).to be false
        end
      end

      context 'when success' do
        before do
          @paga_transaction.status = Spree::PagaTransaction::SUCCESSFUL
          @paga_transaction.save
        end

        it "return true for success" do
          expect(@paga_transaction.success?).to be true
        end
      end
    end

    describe 'unsuccessful?' do
      context 'when not succesfull' do
        before do
          @paga_transaction.status = Spree::PagaTransaction::UNSUCCESSFUL
          allow(@paga_transaction).to receive(:order_set_failure_for_payment).and_return(true)
          @paga_transaction.save
        end

        it "return true if not success" do
          expect(@paga_transaction.unsuccessful?).to be true
        end
      end

      context 'when success' do
        before do
          @paga_transaction.status = Spree::PagaTransaction::SUCCESSFUL
          @paga_transaction.save
        end

        it "return false for success" do
          expect(@paga_transaction.unsuccessful?).to be_falsey
        end
      end
    end

    describe 'pending?' do
      context 'when not pending' do
        before do
          allow(@paga_transaction).to receive(:status).and_return("Pending")
        end

        it "return true if pending" do
          expect(@paga_transaction.pending?).to be_truthy
        end
      end

      context 'when not pending' do
        before do
          @paga_transaction.status = Spree::PagaTransaction::SUCCESSFUL
          @paga_transaction.save
        end

        it "return false for success" do
          expect(@paga_transaction.pending?).to be_falsey
        end
      end
    end

    describe 'amount_valid?' do
      context 'when amount valid' do
        before do
          allow(@order).to receive(:remaining_total).and_return(100)
          allow(@paga_transaction).to receive(:amount).and_return(100)
        end

        it "should return true" do
          expect(@paga_transaction.amount_valid?).to be_truthy
        end
      end

      context 'when amount is not valid' do
        before do
          allow(@order).to receive(:remaining_total).and_return(200)
          allow(@paga_transaction).to receive(:amount).and_return(100)
        end

        it "should return false" do
          expect(@paga_transaction.amount_valid?).to be_falsey
        end
      end
    end

    describe 'currency' do
      it "should give currency" do
        expect(@order.currency).to eq(@paga_transaction.currency)
      end
    end

    describe 'update_transaction' do
      before do
        @paga_transaction.update_transaction({fee: 5, total: 100, status: "Approved", transaction_id: "trans123"})
      end

      it 'should set paga fee' do
        expect(@paga_transaction.paga_fee).to eq(5)
      end

      it "should set total" do
        expect(@paga_transaction.amount).to eq(100)
      end

      it "should set response_status" do
        expect(@paga_transaction.response_status).to eq("Approved")
      end

      context 'when transaction_id present' do

        it "should set transaction_id from params" do
          expect(@paga_transaction.transaction_id).to eq("trans123")
        end
      end

      context 'when not present' do
        before do
          @paga_transaction.update_transaction({fee: 5, total: 100, status: "Approved", transaction_id: ""})
        end

        it "should generate transaction_id" do
          expect(@paga_transaction.reload.transaction_id).to be_present
        end
      end
    end

    describe 'set_pending_for_payment' do
      before do
        @paga_payment_method = Spree::PaymentMethod::Paga.create(name: "paga epay")
        @paga_payment = @order.payments.create!(amount: 100, payment_method_id: @paga_payment_method.id) { |p| p.state = 'checkout' }
        @paga_transaction.update_attributes({status: "Pending"})
      end

      it "should set paga_payment to pending" do
        expect(@paga_payment.reload.state).to eq("pending")
      end
    end

    describe 'order_set_failure_for_payment' do
      before do
        @paga_payment_method = Spree::PaymentMethod::Paga.create(name: "paga epay")
        @paga_payment = @order.payments.create!(amount: 100, payment_method_id: @paga_payment_method.id) { |p| p.state = 'processing' }
        @paga_transaction.update_attributes({status: "Unsuccessful", transaction_id: "trans"})
      end

      it "should set paga_payment to pending" do
        expect(@paga_payment.reload.state).to eq("failed")
      end
    end

    describe 'finalize_order' do
      before do
        allow_any_instance_of(Spree::PagaTransaction).to receive(:finalize_order).and_call_original
        @paga_transaction.update_column(:status, "Pending")
        @paga_payment_method = Spree::PaymentMethod::Paga.create(name: "paga epay")
        @paga_payment = @order.payments.create!(amount: 100, payment_method_id: @paga_payment_method.id) { |p| p.state = 'processing' }
        @paga_transaction.update_attributes({status: "Successful"})
      end

      it "should complete order" do
        expect(@order.reload).not_to be_completed
        expect(@paga_payment.reload.state).to eq("processing")
      end
    end

    describe 'update_payment_source' do
      before do
        allow_any_instance_of(Spree::PagaTransaction).to receive(:update_payment_source).and_call_original
        allow_any_instance_of(Spree::PagaTransaction).to receive(:assign_values).and_call_original
        @order = Spree::Order.create!({currency: "USD"})
        @order.update_column(:total, 100)
        @paga_payment_method = Spree::PaymentMethod::Paga.create(name: "paga epay")
        @paga_payment = @order.payments.create!(amount: 100, payment_method_id: @paga_payment_method.id) { |p| p.state = 'processing' }
        @paga_transaction = Spree::PagaTransaction.new({amount: 100})
        @paga_transaction.order = @order
        @paga_transaction.transaction_id = 3
        @paga_transaction.save!
      end

      it "should add source to payment" do
        expect(@paga_payment.reload.source).to eq(Spree::PaymentMethod::Paga.first)
        expect(@paga_payment.state).to eq("processing")
      end

    end

    describe 'update_transaction_status' do
      context 'when notification present for transaction' do
        before do
          @paga_notification = Spree::PagaNotification.new
          @paga_notification.transaction_id = @paga_transaction.transaction_id
          @paga_notification.amount = @paga_transaction.amount
          @paga_notification.save!
        end

        it "should not be succesful" do
          expect(@paga_transaction.reload).to be_success
        end
      end

      context 'when notification absent for transaction' do
        it "should not be succesful" do
          expect(@paga_transaction).not_to be_success
        end
      end
    end

  end

end
