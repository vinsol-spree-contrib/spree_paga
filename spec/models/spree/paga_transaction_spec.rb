require 'spec_helper'

describe Spree::PagaTransaction do
  before do
    Spree::PagaTransaction.any_instance.stub(:assign_values).and_return(true)
    Spree::PagaTransaction.any_instance.stub(:response_status?).and_return(true)
    Spree::PagaTransaction.any_instance.stub(:update_transaction_status).and_return(true)
    Spree::PagaTransaction.any_instance.stub(:update_payment_source).and_return(true)
    Spree::PagaTransaction.any_instance.stub(:finalize_order).and_return(true)
  end

  it { Spree::PagaTransaction::PENDING.should eq("Pending") }
  it { Spree::PagaTransaction::SUCCESSFUL.should eq("Successful") }
  it { Spree::PagaTransaction::UNSUCCESSFUL.should eq("Unsuccessful") }

  it {should belong_to(:order)}
  it {should belong_to(:user)}

  it { should validate_numericality_of(:amount).is_greater_than_or_equal_to(Spree::PagaTransaction::MINIMUM_AMT)}
  it { should validate_presence_of(:transaction_id)}
  it { should validate_presence_of(:order)}
  it { should validate_uniqueness_of(:transaction_id)}

  describe 'methods' do
    before do
      @order = Spree::Order.create!({:currency => "USD"}, :without_protection => true)
      @order.update_column(:total, 100)
      @paga_transaction = Spree::PagaTransaction.new({:amount => 100}, :without_protection => true)
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

    describe 'unsuccessful?' do
      context 'when not succesfull' do
        before do
          @paga_transaction.status = Spree::PagaTransaction::UNSUCCESSFUL
          @paga_transaction.stub(:order_set_failure_for_payment).and_return(true)
          @paga_transaction.save
        end

        it "return true if not success" do
          @paga_transaction.unsuccessful?.should be_true
        end
      end

      context 'when success' do
        before do
          @paga_transaction.status = Spree::PagaTransaction::SUCCESSFUL
          @paga_transaction.save
        end

        it "return false for success" do
          @paga_transaction.unsuccessful?.should be_false
        end
      end
    end

    describe 'pending?' do
      context 'when not pending' do
        before do
          @paga_transaction.stub(:status).and_return("Pending")
        end

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

    describe 'currency' do
      it "should give currency" do
        @order.currency.should eq(@paga_transaction.currency)
      end
    end

    describe 'update_transaction' do
      before do
        @paga_transaction.update_transaction({:fee => 5, :total => 100, :status => "Approved", :transaction_id => "trans123"})
      end

      it 'should set paga fee' do
        @paga_transaction.paga_fee.should eq(5)
      end

      it "should set total" do
        @paga_transaction.amount.should eq(100)
      end

      it "should set response_status" do
        @paga_transaction.response_status.should eq("Approved")
      end

      context 'when transaction_id present' do

        it "should set transaction_id from params" do
          @paga_transaction.transaction_id.should eq("trans123")
        end
      end

      context 'when not present' do
        before do
          @paga_transaction.update_transaction({:fee => 5, :total => 100, :status => "Approved", :transaction_id => ""})
        end

        it "should generate transaction_id" do
          @paga_transaction.reload.transaction_id.should be_present
        end
      end
    end

    describe 'set_pending_for_payment' do
      before do
        @paga_payment_method = Spree::PaymentMethod::Paga.create(:name => "paga epay", :environment => Rails.env)
        @paga_payment = @order.payments.create!(:amount => 100, :payment_method_id => @paga_payment_method.id) { |p| p.state = 'checkout' }
        @paga_transaction.update_attributes({:status => "Pending"}, :without_protection => true)
      end

      it "should set paga_payment to pending" do
        @paga_payment.reload.state.should eq("pending")
      end
    end

    describe 'order_set_failure_for_payment' do
      before do
        @paga_payment_method = Spree::PaymentMethod::Paga.create(:name => "paga epay", :environment => Rails.env)
        @paga_payment = @order.payments.create!(:amount => 100, :payment_method_id => @paga_payment_method.id) { |p| p.state = 'processing' }
        @paga_transaction.update_attributes({:status => "Unsuccessful", :transaction_id => "trans"}, :without_protection => true)
      end

      it "should set paga_payment to pending" do
        @paga_payment.reload.state.should eq("failed")
      end
    end

    describe 'finalize_order' do
      before do
        Spree::PagaTransaction.any_instance.unstub(:finalize_order)
        @paga_transaction.update_column(:status, "Pending")
        @paga_payment_method = Spree::PaymentMethod::Paga.create(:name => "paga epay", :environment => Rails.env)
        @paga_payment = @order.payments.create!(:amount => 100, :payment_method_id => @paga_payment_method.id) { |p| p.state = 'processing' }
        @paga_transaction.update_attributes({:status => "Successful"}, :without_protection => true)
      end

      it "should complete order" do
        @order.reload.should be_completed
        @paga_payment.reload.state.should eq("completed")
      end
    end

    describe 'update_payment_source' do
      before do
        Spree::PagaTransaction.any_instance.unstub(:update_payment_source)
        Spree::PagaTransaction.any_instance.unstub(:assign_values)
        @order = Spree::Order.create!({:currency => "USD"}, :without_protection => true)
        @order.update_column(:total, 100)
        @paga_payment_method = Spree::PaymentMethod::Paga.create(:name => "paga epay", :environment => Rails.env)
        @paga_payment = @order.payments.create!(:amount => 100, :payment_method_id => @paga_payment_method.id) { |p| p.state = 'processing' }
        @paga_transaction = Spree::PagaTransaction.new({:amount => 100}, :without_protection => true)
        @paga_transaction.order = @order
        @paga_transaction.transaction_id = 3
        @paga_transaction.save!
      end

      it "should add source to payment" do
        @paga_payment.reload.source.should eq(Spree::PaymentMethod::Paga.first)
        @paga_payment.state.should eq("processing")
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