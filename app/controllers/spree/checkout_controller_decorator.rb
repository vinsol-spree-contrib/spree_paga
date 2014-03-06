Spree::CheckoutController.class_eval do
  skip_before_filter :verify_authenticity_token, :only => [:confirm_paga_payment, :paga_callback, :paga_notification]

  before_filter :redirect_to_paga_if_payment_by_paga, :only => [:update]
  before_filter :authenticate_merchant_key, :only => :paga_callback
  before_filter :authenticate_notification_key, :only => :paga_notification
  helper_method :payment_method

  def confirm_paga_payment
    @transaction = @order.paga_transactions.new
    unless @transaction.valid?
      if @transaction.errors[:amount].any?
        flash[:error] = "Amount #{@transaction.errors["amount"].join}"
      else
        flash[:error] = "Something went wrong. Please try again"
      end
      redirect_to spree.cart_path and return
    end
  end

  def paga_callback
    @transaction = @order.paga_transactions.create { |t| t.user = spree_current_user }
    if params[:status] == "SUCCESS" && @transaction.persisted?
      handle_paga_response!
    elsif params[:status] && @transaction.persisted?
      set_unsuccesful_transaction_status_and_redirect and return
    else
      redirect_to(spree.root_path, :flash => { :error => "Invalid Request!" }) and return
    end
  end


  def paga_notification
    Spree::PagaNotification.build_with_params(params, transaction_id) unless Spree::PagaNotification.where(:transaction_id => params[:transaction_id]).first
    render :nothing => true
  end

  private

    def redirect_to_paga_if_payment_by_paga
      if params[:state] == "payment" && params[:order][:payments_attributes]
        payment_method = Spree::PaymentMethod.where(:id => (paga_payment_attributes(params[:order][:payments_attributes])[:payment_method_id])).first
        if payment_method.kind_of?(Spree::PaymentMethod::Paga)
          if @order.update_attributes(object_params)
            after_update_attributes
          end
          redirect_to(confirm_paga_payment_path) and return
        end
      end
    end

    def paga_payment_attributes(payment_attributes)
      payment_attributes.select { |payment| payment[:payment_method_id] == payment_method.id.to_s }.first
    end

    def authenticate_merchant_key
      redirect_to(spree.root_path, :flash => { :error => "Invalid Request!" }) unless params[:key] == payment_method.preferred_merchant_key
    end

    def authenticate_notification_key
      render :nothing => true unless params[:notification_private_key] == payment_method.preferred_private_notification_key
    end

    def handle_paga_response!
      @transaction.update_transaction(params)
      create_notification if Rails.env.development?
      process_transaction
    end

    def process_transaction
      if @transaction.reload.success?
        complete_order
      else
        flash[:error] = "We are unable to process your payment <br/> Please keep this Transaction number: #{@transaction.transaction_id} for future reference".html_safe
        redirect_to checkout_state_path(:state => "payment") and return
      end
    end

    def payment_method
      Spree::PaymentMethod::Paga.first
    end

    def complete_order
      flash[:notice] = Spree.t(:order_processed_successfully)
      session[:order_id] = nil
      redirect_to completion_route and return
    end

    def set_unsuccesful_transaction_status_and_redirect
      @transaction.response_status = params[:status]
      @transaction.status = Spree::PagaTransaction::UNSUCCESSFUL
      @transaction.save
      flash[:error] = "Transaction Failed." + "<br/>" + "Reason: " + params[:status]
      redirect_to checkout_state_path(:state => "payment")
    end

    ### creating notification for testing in development/test environment
    def create_notification
      transaction_response = Spree::PagaNotification.new
      transaction_response.transaction_id = @transaction.transaction_id
      transaction_response.amount = params['total'].to_f
      transaction_response.save
    end

end