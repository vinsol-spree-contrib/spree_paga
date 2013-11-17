require 'spec_helper'


describe Spree::CheckoutController do
  let(:order) { mock_model(Spree::Order, :remaining_total => 1000, :state => 'payment') }
  let(:user) { mock_model(Spree::User, :store_credits_total => 500) }
  let(:paga_payment_method) { mock_model(Spree::PaymentMethod::Paga) }
  let(:paga_transaction) { mock_model(Spree::PagaTransaction, :transaction_id => 11) }
  let(:paga_notification) { mock_model(Spree::PagaNotification, :transaction_id => 11) }
  let(:paga_payment) {mock_model(Spree::Payment)}

  before(:each) do  
    user.stub(:generate_spree_api_key!).and_return(true)
    user.stub(:last_incomplete_spree_order).and_return(nil)
    order.stub(:token).and_return(1000)
  end

  describe '#update' do
    def send_request(params = {})
      put :update, params.merge!(:use_route => 'spree', :id => order.id)
    end

    before(:each) do
      controller.stub(:ensure_order_not_completed).and_return(true)
      controller.stub(:ensure_checkout_allowed).and_return(true)
      controller.stub(:ensure_sufficient_stock_lines).and_return(true)
      controller.stub(:ensure_valid_state).and_return(true)
      controller.stub(:associate_user).and_return(true)
      controller.stub(:check_authorization).and_return(true)
      controller.stub(:current_order).and_return(order)  
      controller.stub(:setup_for_current_state).and_return(true)
      controller.stub(:spree_current_user).and_return(user)
      order.stub(:has_checkout_step?).with("payment").and_return(true)
      order.stub(:payment?).and_return(true)
      Spree::PaymentMethod::Paga.stub(:first).and_return(paga_payment_method)
      controller.stub(:after_update_attributes).and_return(false)
      order.stub(:update_attributes).and_return(true)
      order.stub(:next).and_return(true)
      order.stub(:completed?).and_return(true)
      order.stub(:can_go_to_state?).and_return(false)
      order.stub(:state=).and_return("payment")
      Spree::PaymentMethod.stub(:where).and_return([paga_payment_method])
      Spree::PaymentMethod::Paga.stub(:first).and_return(paga_payment_method)
      controller.stub(:paga_payment_attributes).and_return({"payment_method_id" => paga_payment_method.id.to_s})
    end

    describe 'redirect_to_paga_if_payment_by_paga' do
      before do
      end

      it "should receive where on Spree::PaymentMethod" do
        Spree::PaymentMethod.should_receive(:where).with(:id => paga_payment_method.id.to_s).and_return([paga_payment_method])
        send_request(:order => { :payments_attributes => [{:payment_method_id => paga_payment_method.id}]}, :state => "payment")
      end

      context 'when payment_method kind_of Spree::PaymentMethod::Paga' do
        it "should_receive update_attributes" do
          order.should_receive(:update_attributes).and_return(true)
          controller.should_receive(:object_params)
          send_request(:order => { :payments_attributes => [{:payment_method_id => paga_payment_method.id}]}, :state => "payment")
        end

        it "should redirect to confirm_paga_payment_path" do
          send_request(:order => { :payments_attributes => [{:payment_method_id => paga_payment_method.id}]}, :state => "payment")
          response.should redirect_to("/confirm_paga_payment")
        end

        context 'when update_attributes true' do
          before do
            order.stub(:update_attributes).and_return(true)
          end

          it "should_receive after_update_attributes" do
            controller.should_receive(:after_update_attributes).and_return(true)
            send_request(:order => { :payments_attributes => [{:payment_method_id => paga_payment_method.id}]}, :state => "payment")
          end
        end
      end

      context 'when payment_method not kind_of PaymentMethod' do
        before do
          paga_payment_method.stub(:kind_of?).and_return(false)
        end

        it "should_receive update_attributes" do
          send_request(:order => { :payments_attributes => [{:payment_method_id => 3}]}, :state => "payment")
          response.should_not redirect_to("/confirm_paga_payment")
        end        
      end

    end

    describe 'paga_callback' do
      def send_request(params = {})
        post :paga_callback, params.merge!(:use_route => 'spree')
      end

      before do
        order.stub(:build_paga_transaction).and_return(paga_transaction)
        paga_transaction.stub(:user=).and_return(user)
        controller.stub(:authenticate_merchant_key).and_return(true)
      end

      it "should receive build_paga_transaction" do
        order.should_receive(:build_paga_transaction).and_return(paga_transaction)
        send_request
      end

      it "should_receive user=" do
        paga_transaction.should_receive(:user=).and_return(user)
        send_request
      end

      context 'when not authenticate_merchant_key and status is not present' do
        before do
          controller.stub(:authenticate_merchant_key).and_return(false)
        end

        it "should redirect to root" do
          send_request
          response.should redirect_to(spree.root_path)
        end

        it "should set flash message" do
          send_request
          flash[:error].should eq("Invalid Request!")
        end
      end

      context 'when authenticate_merchant_key invalid but status present' do
        before do
          paga_transaction.stub(:status=).and_return("Pending")
          paga_transaction.stub(:response_status=).and_return("Pending")
          paga_transaction.stub(:save).and_return(true)
        end

        context 'set_unsuccesful_transaction_status_and_redirect' do
          it "should_receive receive status" do
            paga_transaction.should_receive(:status=).with(Spree::PagaTransaction::UNSUCCESSFUL).and_return("Pending")
            send_request({:status => "Pending"})
          end

          it "should_receive receive response status" do
            paga_transaction.should_receive(:response_status=).and_return("Pending")
            send_request({:status => "Pending"})
          end

          it "should_receive save" do
            paga_transaction.should_receive(:save).and_return(true)
            send_request({:status => "Pending"})
          end

          it "should set flash message" do
            send_request({:status => "Pending"})
            flash[:error].should eq("Transaction Failed." + "<br/>" + "Reason: " + "Pending")
          end

          it "should redirect_to root_path" do
            send_request({:status => "Pending"})
            response.should redirect_to(spree.root_path)
          end
        end
      end

      context 'when authenticate_merchant_key and status success' do
        before do
          controller.stub(:authenticate_merchant_key).and_return(true)
        end

        context 'transaction valid' do
          before do
            paga_transaction.stub(:valid?).and_return(true)
          end

          describe 'handle_paga_response!' do
            before do
              paga_transaction.stub(:amount=).and_return(100)
              paga_transaction.stub(:transaction_id=).and_return("100")
              paga_transaction.stub(:paga_fee=).and_return(100)
              paga_transaction.stub(:response_status=).and_return("SUCCESS")
              paga_transaction.stub(:save).and_return(true)
              order.stub(:paga_payment).and_return(paga_payment)
              paga_payment.stub(:source=).and_return(paga_payment_method)
              paga_payment.stub(:save).and_return(true)
              paga_payment.stub(:started_processing!).and_return(true)
              paga_transaction.stub(:reload).and_return(paga_transaction)
              paga_transaction.stub(:success?).and_return(true)
              paga_transaction.stub(:amount_valid?).and_return(true)
              order.stub(:finalize_order).and_return(true)
            end

            it "should_receive set_paga_transaction_details" do
              controller.should_receive(:set_paga_transaction_details).and_return(true)
              send_request({:status => "SUCCESS", :total => "100", :transaction_id => "12"})
            end

            context 'set_paga_transaction_details' do
              it "should_receive paga_fee" do
                paga_transaction.should_receive(:paga_fee=).and_return(100.0)
                send_request({:status => "SUCCESS", :total => "100", :transaction_id => "12"})
              end

              it "should_receive transaction_id" do
                paga_transaction.should_receive(:transaction_id=).and_return("12")
                send_request({:status => "SUCCESS", :total => "100", :transaction_id => "12"})
              end

              it "should_receive response_status=" do
                paga_transaction.should_receive(:response_status=).and_return("SUCCESS")
                send_request({:status => "SUCCESS", :total => "100", :transaction_id => "12"})
              end

              it "should_receive save" do
                paga_transaction.should_receive(:save).and_return(true)
                send_request({:status => "SUCCESS", :total => "100", :transaction_id => "12"})
              end
            end

            describe 'process_transaction' do
              context 'when Transaction is success' do
                context 'when amount_valid true' do
                  describe 'finalize_order' do
                    it "order should_receive finalize_order" do
                      order.should_receive(:finalize_order).and_return(true)
                      send_request({:status => "SUCCESS", :total => "100", :transaction_id => "12"})
                    end

                    it "should set session to nil" do
                      send_request({:status => "SUCCESS", :total => "100", :transaction_id => "12"})
                      session[:order_id].should be_nil
                    end

                    it "should set flash message" do
                      send_request({:status => "SUCCESS", :total => "100", :transaction_id => "12"})
                      flash[:notice].should eq(Spree.t(:order_processed_successfully))
                    end

                    it "should redirect_to completion_route" do
                      send_request({:status => "SUCCESS", :total => "100", :transaction_id => "12"})
                      response.should redirect_to(spree.order_path(order))
                    end
                  end
                end
                context 'when amount_valid false' do
                  before do
                    paga_transaction.stub(:amount_valid?).and_return(false)
                    paga_payment.stub(:pend!).and_return(true)
                  end

                  it "should redirect_to checkout_state_path(:state => payment)" do
                    send_request({:status => "SUCCESS", :total => "100", :transaction_id => "12"})
                    response.should redirect_to(spree.checkout_state_path(:state => "payment"))
                  end

                  describe 'set_to_payment_pending' do
                    it "should_receive Pending on payment" do
                      paga_payment.should_receive(:pend!).and_return(true)
                      send_request({:status => "SUCCESS", :total => "100", :transaction_id => "12"})
                    end

                    it "should set flash message" do
                      send_request({:status => "SUCCESS", :total => "100", :transaction_id => "12"})
                      flash[:error].should eq("We are sorry. We are unable to authorize your purchase amount. Please contact our Administrator.")
                    end
                  end
                end
              end

              context 'when transaction is Pending' do
                before do
                  paga_transaction.stub(:success?).and_return(false)
                  paga_transaction.stub(:pending?).and_return(true)
                  order.stub(:pending!).and_return(true)
                  paga_payment.stub(:pend!).and_return(true)
                end

                it "should receive set_to_payment_pending" do
                  controller.should_receive(:set_to_payment_pending).with(paga_payment).and_return(true)
                  send_request({:status => "SUCCESS", :total => "100", :transaction_id => "12"})
                end

                it "should_receive pending on order" do
                  order.should_receive(:pending!).and_return(true)
                  send_request({:status => "SUCCESS", :total => "100", :transaction_id => "12"})
                end

                it "should set session to nil" do
                  send_request({:status => "SUCCESS", :total => "100", :transaction_id => "12"})
                  session[:order_id].should be_nil
                end

                it "should redirect_to completion_route" do
                  send_request({:status => "SUCCESS", :total => "100", :transaction_id => "12"})
                  response.should redirect_to(spree.order_path(order))
                end
              end

              context 'when transaction is neither pending nor success' do
                before do
                  paga_transaction.stub(:success?).and_return(false)
                  paga_transaction.stub(:pending?).and_return(false)
                  paga_payment.stub(:failure!).and_return(true)
                end

                it "should_receive failure on payment" do
                  paga_payment.should_receive(:failure!).and_return(true)
                  send_request({:status => "SUCCESS", :total => "100", :transaction_id => "12"})
                end

                it "should redirect_to edit checkout path" do
                  send_request({:status => "SUCCESS", :total => "100", :transaction_id => "12"})
                  response.should redirect_to(spree.checkout_state_path(:state => "payment"))
                end
              end
            end

          end

        end

        context 'transaction invalid' do
          before do
            paga_transaction.stub(:valid?).and_return(false)
          end
          it "should redirect to root" do
            send_request({:status => "SUCCESS"})
            response.should redirect_to(spree.root_path)
          end

          it "should set flash message" do
            send_request({:status => "SUCCESS"})
            flash[:error].should eq("Invalid Request!")
          end

        end
      end

    end

    describe 'paga_notification' do
      before do
        controller.stub(:authentic_request?).and_return(true)
      end

      def send_request
        post :paga_notification, :transaction_id => paga_notification.id, :use_route => "spree"
      end

      it "should_receive where" do
        Spree::PagaNotification.should_receive(:where).with(:transaction_id => paga_notification.id.to_s).and_return([paga_notification])
        send_request
      end

      it "should render nothing" do
        send_request
        response.body.should be_blank
      end

      context 'when request is valid' do
        it "should build notification" do
          Spree::PagaNotification.should_receive(:build_with_params).and_return(true)
          send_request
        end
      end
    end


    describe 'confirm_paga_payment' do
      before do
        order.stub(:remaining_total).and_return(100)
      end

      def send_request
        get :confirm_paga_payment, :use_route => "spree"
      end

      it "should_receive remaining total" do
        order.should_receive(:remaining_total).and_return(100)
        send_request
      end

      it "should receive new on transaction" do
        Spree::PagaTransaction.should_receive(:new).with(:amount => 100).and_return(paga_transaction)
        send_request
      end

      context 'when transaction valid' do
        before do
          Spree::PagaTransaction.stub(:new).and_return(paga_transaction)
          paga_transaction.stub(:valid?).and_return(true)
        end

        it "should render confirm_paga_payment" do
          send_request
          response.should render_template(:confirm_paga_payment)
        end
      end

      context 'when transaction invalid' do
        before do
          Spree::PagaTransaction.stub(:new).and_return(paga_transaction)
          paga_transaction.stub(:valid?).and_return(false)
        end

        it "should redirect to spree.cart_path" do
          send_request
          response.should redirect_to(spree.cart_path)
        end

        it "set flash message" do
          send_request
          flash[:error].should eq("Something went wrong. Please try again")
        end

        it "sets error for amount if error for amount present" do
          paga_transaction.stub_chain(:errors, :[]).and_return(["is invalid"])
          send_request
          flash[:error].should eq("Amount is invalid")
        end
      end
    end
  end

  describe 'authenticate_merchant_key' do
    before do
      controller.stub(:payment_method).and_return(paga_payment_method)
      paga_payment_method.stub(:preferred_merchant_key).and_return("my_key")
    end

    it "should return true if key is correct" do
      controller.send(:authenticate_merchant_key, "my_key").should be_true
    end

    it "should return false if key is incorrect" do
      controller.send(:authenticate_merchant_key, " wrong key").should be_false      
    end
  end

  describe 'authenticate_notification_key' do
    before do
      controller.stub(:payment_method).and_return(paga_payment_method)
      paga_payment_method.stub(:preferred_private_notification_key).and_return("my_key")
    end

    it "should return true if key is correct" do
      controller.send(:authenticate_notification_key, "my_key").should be_true
    end

    it "should return false if key is incorrect" do
      controller.send(:authenticate_notification_key, " wrong key").should be_false      
    end
  end

  describe 'authentic_request?' do
    context 'when authenticate_notification_key and authenticate_merchant_key is true' do
      before do
        controller.stub(:authenticate_merchant_key).and_return(true)
        controller.stub(:authenticate_notification_key).and_return(true)
      end

      it "should return true" do
        controller.send(:authentic_request?).should be_true
      end
    end

    context 'when authenticate_notification_key is true and authenticate_merchant_key is false' do
      before do
        controller.stub(:authenticate_merchant_key).and_return(false)
        controller.stub(:authenticate_notification_key).and_return(true)
      end

      it "should return false" do
        controller.send(:authentic_request?).should be_false
      end
    end

    context 'when authenticate_notification_key is false and authenticate_merchant_key is true' do
      before do
        controller.stub(:authenticate_merchant_key).and_return(true)
        controller.stub(:authenticate_notification_key).and_return(false)
      end

      it "should return false" do
        controller.send(:authentic_request?).should be_false
      end
    end
  end

end