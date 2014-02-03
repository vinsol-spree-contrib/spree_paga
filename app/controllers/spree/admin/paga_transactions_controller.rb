module Spree
  module Admin
    class PagaTransactionsController < ResourceController

      def index
        @paga_transactions = Spree::PagaTransaction.scoped.page(params[:page])
      end

      def complete
        @order = @paga_transaction.order
        begin
          #[TODO_CR] First of all finalize_order and tranx update should be in transaction.
          # We should move finalize_order to after callback of tranx update. What you think?
          @order.finalize_order
          @paga_transaction.update_attributes(:status => Spree::PagaTransaction::SUCCESSFUL)
          flash.now[:success] = "Order Completed"
        rescue
          flash.now[:error] = "Sorry order cannot be completed"
        end
      end
    end
  end
end