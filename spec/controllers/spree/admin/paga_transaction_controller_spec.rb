require 'spec_helper'

describe Spree::Admin::PagaTransactionsController do
  let(:user) { mock_model(Spree::User) }

  describe 'index' do
    def send_request
      get :index, page: "1"
    end

    before do
      @paga_transaction = mock_model(Spree::PagaTransaction)
      @paga_transactions = [@paga_transaction]
      allow(controller).to receive(:spree_current_user).and_return(user)
      allow(controller).to receive(:authorize_admin).and_return(true)
      allow(controller).to receive(:authorize!).and_return(true)
      allow(@paga_transaction).to receive(:includes).and_return(@paga_transactions)
      allow(user).to receive(:generate_spree_api_key!).and_return(true)
      allow(controller).to receive(:collection).and_return(@paga_transactions)
      allow(@paga_transactions).to receive(:page).and_return(@paga_transactions)

    end

    it "should_receive page" do
      expect(Spree::PagaTransaction).to receive(:page).with("1").and_return(@paga_transactions)
      send_request
    end

  end


  describe 'complete' do

    def send_request
      xhr :get, :complete, id: @paga_transaction.id
    end

    before do
      @paga_transaction = mock_model(Spree::PagaTransaction)
      @paga_transactions = [@paga_transaction]
      allow(controller).to receive(:spree_current_user).and_return(user)
      allow(controller).to receive(:authorize_admin).and_return(true)
      allow(controller).to receive(:authorize!).and_return(true)
      allow(user).to receive(:generate_spree_api_key!).and_return(true)
      allow(controller).to receive(:load_resource_instance).and_return(@paga_transaction)
      @order = mock_model(Spree::Order)
      allow(@paga_transaction).to receive(:order).and_return(@order)
      allow(@paga_transaction).to receive(:update_attributes).and_return(true)
    end

    it "should receive order" do
      expect(@paga_transaction).to receive(:order).and_return(@order)
      send_request
    end

    it "should receive update_attributes" do
      expect(@paga_transaction).to receive(:update_attributes).with(status: Spree::PagaTransaction::SUCCESSFUL).and_return(true)
      send_request
    end

    it "should set flash message" do
      send_request
      expect(flash.now[:success]).to eq("Order Completed")
    end

    context 'when finalize_order gives exception' do
      before do
        allow(@paga_transaction).to receive(:update_attributes).and_raise
      end

      it "should set flash message" do
        send_request
        expect(flash.now[:error]).to eq("Sorry order cannot be completed")
      end
    end

  end
end
