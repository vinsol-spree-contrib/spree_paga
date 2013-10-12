module Spree
  module Admin
  	PaymentsController.class_eval do

  		private

      def can_transition_to_payment
        unless @order.payment? || @order.complete? || @order.pending?
	        flash[:notice] = Spree.t(:fill_in_customer_info)
  	      redirect_to edit_admin_order_customer_url(@order)
    	  end
    	end
  	end
  end
end
