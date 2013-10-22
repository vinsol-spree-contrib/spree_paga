require 'spec_helper'

describe Spree::Admin::PagaTransactionsController do
  let(:user) { mock_model(Spree::User) }

  describe 'index' do
    def send_request
      get :index, :page => "1", :use_route => "spree"
    end

    before do
      @paga_transaction = mock_model(Spree::PagaTransaction)
      @paga_transactions = [@paga_transaction]
      controller.stub(:spree_current_user).and_return(user)
      controller.stub(:authorize_admin).and_return(true)
      controller.stub(:authorize!).and_return(true)
      user.stub(:generate_spree_api_key!).and_return(true)
      controller.stub(:collection).and_return(@paga_transactions)
      Spree::PagaTransaction.stub(:scoped).and_return(@paga_transactions)
      @paga_transactions.stub(:page).and_return(@paga_transactions)
    end

    it "should receive scoped" do
      Spree::PagaTransaction.should_receive(:scoped).and_return(@paga_transactions)
      send_request
    end

    it "should_receive page" do
      @paga_transactions.should_receive(:page).with("1").and_return(@paga_transactions)
      send_request
    end

  end


  describe 'complete' do

    def send_request
      xhr :get, :complete, :id => @paga_transaction.id, :use_route => "spree"
    end

    before do
      @paga_transaction = mock_model(Spree::PagaTransaction)
      @paga_transactions = [@paga_transaction]
      controller.stub(:spree_current_user).and_return(user)
      controller.stub(:authorize_admin).and_return(true)
      controller.stub(:authorize!).and_return(true)
      user.stub(:generate_spree_api_key!).and_return(true)
      controller.stub(:load_resource_instance).and_return(@paga_transaction)
      @order = mock_model(Spree::Order)
      @paga_transaction.stub(:order).and_return(@order)
      @order.stub(:finalize_order).and_return(true)
      @paga_transaction.stub(:update_attributes).and_return(true)
    end

    it "should receive order" do
      @paga_transaction.should_receive(:order).and_return(@order)
      send_request
    end

    it "should receive finalize_order on order" do
      @order.should_receive(:finalize_order).and_return(true)
      send_request
    end

    it "should receive update_attributes" do
      @paga_transaction.should_receive(:update_attributes).with(:status => Spree::PagaTransaction::SUCCESSFUL).and_return(true)
      send_request
    end

    it "should set flash message" do
      send_request
      flash.now[:success].should eq("Order Completed")
    end

    context 'when finalize_order gives exception' do
      before do
        @order.stub(:finalize_order).and_raise
      end

      it "should set flash message" do
        send_request
        flash.now[:error].should eq("Sorry order cannot be completed")
      end
    end

  end
end