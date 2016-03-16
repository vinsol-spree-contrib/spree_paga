require 'spec_helper'


describe Spree::CheckoutController do
  let(:order) { mock_model(Spree::Order, remaining_total: 1000, state: 'payment') }
  let(:user) { mock_model(Spree::User, store_credits_total: 500) }
  let(:paga_payment_method) { mock_model(Spree::PaymentMethod::Paga) }
  let(:paga_transaction) { mock_model(Spree::PagaTransaction, transaction_id: 11) }
  let(:paga_notification) { mock_model(Spree::PagaNotification, transaction_id: 11) }
  let(:paga_payment) {mock_model(Spree::Payment)}

  before(:each) do
    allow(user).to receive(:generate_spree_api_key!).and_return(true)
    allow(user).to receive(:orders).and_return(Spree::Order.all)
    allow(order).to receive(:incomplete).and_return(true)
    allow(user).to receive(:last_incomplete_spree_order).and_return(nil)
    allow(order).to receive(:token).and_return(1000)
  end

  describe '#update' do
    def send_request(params = {})
      put :update, params.merge!(id: order.id)
    end

    before(:each) do
      allow(controller).to receive(:ensure_order_not_completed).and_return(true)
      allow(controller).to receive(:ensure_checkout_allowed).and_return(true)
      allow(controller).to receive(:ensure_sufficient_stock_lines).and_return(true)
      allow(controller).to receive(:ensure_valid_state).and_return(true)
      allow(controller).to receive(:associate_user).and_return(true)
      allow(controller).to receive(:check_authorization).and_return(true)
      allow(controller).to receive(:current_order).and_return(order)
      allow(controller).to receive(:setup_for_current_state).and_return(true)
      allow(controller).to receive(:spree_current_user).and_return(user)
      allow(order).to receive(:has_checkout_step?).with("payment").and_return(true)
      allow(order).to receive(:payment?).and_return(true)
      allow(Spree::PaymentMethod::Paga).to receive(:first).and_return(paga_payment_method)
      allow(order).to receive(:update_from_params).and_return(true)
      allow(order).to receive(:next).and_return(true)
      allow(order).to receive(:completed?).and_return(true)
      allow(order).to receive(:can_go_to_state?).and_return(false)
      allow(order).to receive(:state=).and_return("payment")
      allow(Spree::PaymentMethod).to receive(:find_by).and_return(paga_payment_method)
      allow(controller).to receive(:paga_payment_attributes).and_return({payment_method_id: paga_payment_method.id.to_s})
      allow(order).to receive(:temporary_address=).and_return(true)
    end

    describe 'redirect_to_paga_if_payment_by_paga' do
      before do
      end

      it "should receive where on Spree::PaymentMethod" do
        expect(Spree::PaymentMethod).to receive(:find_by).with(id: paga_payment_method.id.to_s).and_return(paga_payment_method)
        send_request(order: { payments_attributes: [{payment_method_id: paga_payment_method.id}]}, state: "payment")
      end

      context 'when payment_method kind_of Spree::PaymentMethod::Paga' do
        it "should_receive update_from_params" do
          expect(order).to receive(:update_from_params).and_return(true)
          send_request(order: { payments_attributes: [{payment_method_id: paga_payment_method.id}]}, state: "payment")
        end

        it "should redirect to confirm_paga_payment_path" do
          send_request(order: { payments_attributes: [{payment_method_id: paga_payment_method.id}]}, state: "payment")
          expect(response).to redirect_to("/confirm_paga_payment")
        end
      end

      context 'when payment_method not kind_of PaymentMethod' do
        before do
          allow(paga_payment_method).to receive(:kind_of?).and_return(false)
        end

        it "should_receive update_attributes" do
          send_request(order: { payments_attributes: [{payment_method_id: 3}]}, state: "payment")
          expect(response).not_to redirect_to("/confirm_paga_payment")
        end
      end

    end

    describe 'paga_callback' do
      def send_request(params = {})
        post :paga_callback, params
      end

      before do
        @paga_transactions = []
        allow(order).to receive(:paga_transactions).and_return(@paga_transactions)
        allow(@paga_transactions).to receive(:create).and_return(paga_transaction)
        allow(paga_transaction).to receive(:user=).and_return(user)
        allow(controller).to receive(:authenticate_merchant_key).and_return(true)
        allow(paga_transaction).to receive(:generate_transaction_id).and_return("trans_id")
        allow(paga_transaction).to receive(:transaction_id=).and_return("trans_id")
      end

      it "should receive build_paga_transaction" do
        expect(order).to receive(:paga_transactions).and_return(@paga_transactions)
        send_request
      end

      it "should_receive user=" do
        allow(@paga_transactions).to receive(:create).and_yield(paga_transaction)
        expect(paga_transaction).to receive(:user=).and_return(user)
        send_request
      end

      context 'when authenticate_merchant_key not valid' do
        before do
          allow(controller).to receive(:authenticate_merchant_key).and_return(false)
        end

        it "should redirect to root" do
          send_request
          expect(response).to redirect_to(spree.root_path)
        end

        it "should set flash message" do
          send_request
          expect(flash[:error]).to eq("Invalid Request!")
        end
      end

      context 'when authenticate_merchant_key and status success' do
        before do
          allow(controller).to receive(:authenticate_merchant_key).and_return(true)
        end

        context 'transaction valid' do
          before do
            allow(paga_transaction).to receive(:persisted?).and_return(true)
          end

          describe 'handle_paga_response!' do
            before do
              allow(paga_transaction).to receive(:amount=).and_return(100)
              allow(paga_transaction).to receive(:transaction_id=).and_return("100")
              allow(paga_transaction).to receive(:paga_fee=).and_return(100)
              allow(paga_transaction).to receive(:response_status=).and_return("SUCCESS")
              allow(paga_transaction).to receive(:save).and_return(true)
              allow(order).to receive(:paga_payment).and_return(paga_payment)
              allow(paga_payment).to receive(:source=).and_return(paga_payment_method)
              allow(paga_payment).to receive(:save).and_return(true)
              allow(paga_payment).to receive(:started_processing!).and_return(true)
              allow(paga_transaction).to receive(:reload).and_return(paga_transaction)
              allow(paga_transaction).to receive(:success?).and_return(true)
              allow(paga_transaction).to receive(:amount_valid?).and_return(true)
              allow(order).to receive(:finalize_order).and_return(true)
              allow(paga_transaction).to receive(:update_transaction).and_return(true)
            end

            it "should_receive update_transaction" do
              expect(paga_transaction).to receive(:update_transaction).with({"status" => "SUCCESS", "total" => "100", "transaction_id" => "12", "controller" => "spree/checkout", "action" => "paga_callback"}).and_return(true)
              send_request({status: "SUCCESS", total: "100", transaction_id: "12"})
            end

            describe 'process_transaction' do
              context 'when Transaction is success' do
                context 'when amount_valid true' do
                  describe 'complete_order' do

                    it "should set session to nil" do
                      send_request({status: "SUCCESS", total: "100", transaction_id: "12"})
                      expect(session[:order_id]).to be_nil
                    end

                    it "should set flash message" do
                      send_request({status: "SUCCESS", total: "100", transaction_id: "12"})
                      expect(flash[:notice]).to eq(Spree.t(:order_processed_successfully))
                    end

                    it "should redirect_to completion_route" do
                      send_request({status: "SUCCESS", total: "100", transaction_id: "12"})
                      expect(response).to redirect_to(spree.order_path(order))
                    end
                  end
                end
                context 'when transaction not successful' do
                  before do
                    allow(paga_transaction).to receive(:success?).and_return(false)
                  end

                  it "should redirect_to checkout_state_path(state: payment)" do
                    send_request({status: "SUCCESS", total: "100", transaction_id: "12"})
                    expect(response).to redirect_to(spree.checkout_state_path(state: "payment"))
                  end


                  it "should set flash message" do
                    send_request({status: "SUCCESS", total: "100", transaction_id: "12"})
                    expect(flash[:error]).to eq("We are unable to process your payment <br/> Please keep this Transaction number: #{paga_transaction.transaction_id} for future reference")
                  end
                end
              end

            end

          end

        end

        context 'when status not sucess' do

          before do
            allow(paga_transaction).to receive(:response_status=).and_return("SUCCESS")
            allow(paga_transaction).to receive(:status=).and_return("SUCCESS")
            allow(paga_transaction).to receive(:save).and_return(true)
          end

          it "should set unsuccessful to transaction" do
            send_request({status: "Not Approved", total: "100", transaction_id: "12"})
            expect(flash[:error]).to eq("Transaction Failed. <br/> Reason: Not Approved <br/> Transaction Reference: #{paga_transaction.transaction_id}")
          end

          it "should_receive response_status= on transaction" do
            expect(paga_transaction).to receive(:response_status=).with("Not Approved").and_return("Not Approved")
            send_request({status: "Not Approved", total: "100", transaction_id: "12"})
          end

          it "should_receive status= on transaction" do
            expect(paga_transaction).to receive(:status=).with(Spree::PagaTransaction::UNSUCCESSFUL).and_return(true)
            send_request({status: "Not Approved", total: "100", transaction_id: "12"})
          end

          it "should_receive transaction_id= on transaction" do
            expect(paga_transaction).to receive(:transaction_id=).with("12").and_return(true)
            send_request({status: "Not Approved", total: "100", transaction_id: "12"})
          end

          it "should_receive save" do
            expect(paga_transaction).to receive(:save).and_return(true)
            send_request({status: "Not Approved", total: "100", transaction_id: "12"})
          end

          it "should redirect_to payment checkout" do
            send_request({status: "Not Approved", total: "100", transaction_id: "12"})
            expect(response).to redirect_to(spree.checkout_state_path(state: "payment"))
          end
        end

        context 'transaction invalid' do
          before do
            allow(paga_transaction).to receive(:persisted?).and_return(false)
          end
          it "should redirect to root" do
            send_request({status: "SUCCESS"})
            expect(response).to redirect_to(spree.root_path)
          end

          it "should set flash message" do
            send_request({status: "SUCCESS"})
            expect(flash[:error]).to eq("Invalid Request!")
          end

        end
      end

    end

    describe 'paga_notification' do
      before do
        allow(controller).to receive(:authenticate_notification_key).and_return(true)
        allow(Spree::PagaNotification).to receive(:build_with_params).and_return(true)
      end

      def send_request
        post :paga_notification, transaction_id: paga_notification.id
      end

      it "should_receive where" do
        expect(Spree::PagaNotification).to receive(:where).with(transaction_id: paga_notification.id.to_s).and_return([paga_notification])
        send_request
      end

      it "should render nothing" do
        send_request
        expect(response.body).to be_blank
      end

      context 'when request is valid' do
        it "should build notification" do
          expect(Spree::PagaNotification).to receive(:build_with_params).and_return(true)
          send_request
        end
      end

      context 'when notification already present' do
        before do
          allow(Spree::PagaNotification).to receive(:where).and_return([])
          expect(Spree::PagaNotification).not_to receive(:build_with_params)
        end
      end
    end


    describe 'confirm_paga_payment' do
      before do
        @paga_transactions = []
        allow(order).to receive(:paga_transactions).and_return(@paga_transactions)
        allow(@paga_transactions).to receive(:new).and_return(paga_transaction)
      end

      def send_request
        get :confirm_paga_payment
      end

      it "should_receive remaining total" do
        expect(order).to receive(:paga_transactions).and_return(@paga_transactions)
        send_request
      end

      it "should receive new on transaction" do
        expect(@paga_transactions).to receive(:new).and_return(paga_transaction)
        send_request
      end

      context 'when transaction valid' do
        before do
          allow(Spree::PagaTransaction).to receive(:new).and_return(paga_transaction)
          allow(paga_transaction).to receive(:valid?).and_return(true)
        end

        it "should render confirm_paga_payment" do
          send_request
          expect(response).to render_template(:confirm_paga_payment)
        end
      end

      context 'when transaction invalid' do
        before do
          allow(Spree::PagaTransaction).to receive(:new).and_return(paga_transaction)
          allow(paga_transaction).to receive(:valid?).and_return(false)
        end

        it "should redirect to spree.cart_path" do
          send_request
          expect(response).to redirect_to(spree.cart_path)
        end

        it "set flash message" do
          send_request
          expect(flash[:error]).to eq("Something went wrong. Please try again")
        end

        it "sets error for amount if error for amount present" do
          allow(paga_transaction).to receive_message_chain(:errors, :[]).and_return(["is invalid"])
          send_request
          expect(flash[:error]).to eq("Amount is invalid")
        end
      end
    end
  end

end
