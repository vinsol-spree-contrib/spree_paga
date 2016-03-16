module Spree
  module Admin
    class PagaTransactionsController < ResourceController

      def index
        @paga_transactions = Spree::PagaTransaction.includes(:order, :user).page(params[:page])
      end

      def complete
        @order = @paga_transaction.order
        begin
          @paga_transaction.update_attributes(status: Spree::PagaTransaction::SUCCESSFUL)
          flash.now[:success] = "Order Completed"
        rescue
          flash.now[:error] = "Sorry order cannot be completed"
        end
      end
    end
  end
end
