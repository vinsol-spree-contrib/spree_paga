require 'spec_helper'


describe Spree::Admin::PaymentsController do
  describe 'can_transition_to_payment' do

    before do
      controller.stub :authorize! => true
      controller.stub(:authorize_admin).and_return(true)
      controller.stub(:load_payment).and_return(true)
      controller.stub(:load_data).and_return(true)
      @order = mock_model(Spree::Order)
      # controller.instance_variable_set(:@order, order)
      # order.stub(:pending?).and_return(false)
      # order.stub(:complete?).and_return(false)
      # order.stub(:payment?).and_return(false)
      Spree::Order.stub find_by_number!: @order
      @order.stub(:payment_required? => true)
    end
    context "try to skip customer details step" do
      # it "redirect to customer details step" do
      #   # get :index, { amount: 100 }
      #   get :index, :use_route => "spree"
      #   response.should redirect_to(spree.edit_admin_order_customer_path(@order))
      # end
    end

    # context 'when order is not complete or payment or pending' do
    #   before do
    #   end

    #   it "should set flash message" do
    #     controller.send(:can_transition_to_payment)
    #     flash[:notice].should eq(Spree.t(:fill_in_customer_info))
    #   end

    #   it "should redirect to customer edit url" do
    #     controller.send(:can_transition_to_payment)
    #     response.should redirect_to(edit_admin_order_customer_url(@order))
    #   end
    # end
  end
end