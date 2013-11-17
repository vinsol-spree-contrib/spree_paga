Spree::CheckoutController.class_eval do
  skip_before_filter :verify_authenticity_token, :only => [:confirm_paga_payment, :paga_callback, :paga_notification]

  before_filter :redirect_to_paga_if_payment_by_paga, :only => [:update]
  helper_method :payment_method

  def confirm_paga_payment
    amount = @order.remaining_total
    @transaction = Spree::PagaTransaction.new(:amount => amount)
    unless @transaction.valid?
      flash[:error] = "Something went wrong. Please try again"
      flash[:error] = "Amount #{@transaction.errors["amount"].join}" if @transaction.errors["amount"].any?
      redirect_to spree.cart_path and return
    end
  end

  def paga_callback
    @transaction = @order.build_paga_transaction(:amount => params[:total].to_f)
    @transaction.user = spree_current_user
    if authenticate_merchant_key(params[:key]) && params['status'] == "SUCCESS" && @transaction.valid?
      handle_paga_response!
    elsif params[:status] && @transaction.valid?
      set_unsuccesful_transaction_status_and_redirect and return
    else
      redirect_to(spree.root_path, :flash => { :error => "Invalid Request!" }) and return
    end
  end


  def paga_notification
    notification = Spree::PagaNotification.where(:transaction_id => params[:transaction_id]).first
    if authentic_request? && !notification
      Spree::PagaNotification.build_with_params(params)
    end
    render :nothing => true
  end

  private

    def redirect_to_paga_if_payment_by_paga
      if params[:state] == "payment" && params[:order][:payments_attributes]
        payment_method = Spree::PaymentMethod.where(:id => (paga_payment_attributes(params[:order][:payments_attributes])["payment_method_id"])).first
        if payment_method.kind_of?(Spree::PaymentMethod::Paga)
          if @order.update_attributes(object_params)
            after_update_attributes
          end
          redirect_to(confirm_paga_payment_path) and return
        end
      end
    end

    def paga_payment_attributes(payment_attributes)
      payment_attributes.select { |payment| payment["payment_method_id"] == payment_method.id.to_s }.first
    end

    def authenticate_merchant_key(key)
      key == payment_method.preferred_merchant_key
    end

    def authenticate_notification_key(key)
      key == payment_method.preferred_private_notification_key
    end

    def handle_paga_response!
      set_paga_transaction_details
      payment = @order.paga_payment
      payment.source = Spree::PaymentMethod::Paga.first
      payment.save
      create_notification if Rails.env.development?
      payment.started_processing!
      process_transaction(payment)
    end

    def process_transaction(payment)
      if @transaction.reload.success?
        if @transaction.amount_valid?
          finalize_order
        else
          set_to_payment_pending(payment)
          redirect_to checkout_state_path(:state => "payment") and return
        end
      elsif @transaction.pending?
        set_to_payment_pending(payment)
        @order.pending!
        session[:order_id] = nil
        redirect_to completion_route and return
      else
        payment.failure!
        redirect_to checkout_state_path(:state => "payment") and return
      end
    end

    def payment_method
      Spree::PaymentMethod::Paga.first
    end

    def set_paga_transaction_details
      if params['transaction_id'] || (params['transaction_id'].blank? && !Rails.env.production?)
        @transaction.transaction_id = get_transaction_id
        @transaction.paga_fee = params[:fee]
      end
      @transaction.response_status = params[:status]
      @transaction.save
    end

    def get_transaction_id
      Rails.env.development? ? ("trans" + @transaction.order.number) : params[:transaction_id]
    end

    def finalize_order
      @order.finalize_order
      session[:order_id] = nil
      flash[:notice] = Spree.t(:order_processed_successfully)
      redirect_to completion_route and return
    end

    def set_unsuccesful_transaction_status_and_redirect
      @transaction.response_status = params[:status]
      @transaction.status = Spree::PagaTransaction::UNSUCCESSFUL
      @transaction.save
      flash[:error] = "Transaction Failed." + "<br/>" + "Reason: " + params[:status]
      redirect_to(spree.root_path)
    end

    def authentic_request?
      authenticate_merchant_key(params[:merchant_key]) && authenticate_notification_key(params[:notification_private_key])
    end

    def set_to_payment_pending(payment)
      payment.pend!
      flash[:error] = "We are sorry. We are unable to authorize your purchase amount. Please contact our Administrator."
    end

    ### creating notification for testing in development/test environment
    def create_notification
      transaction_response = Spree::PagaNotification.new
      transaction_response.transaction_id = get_transaction_id
      transaction_response.amount = params['total'].to_f
      transaction_response.save
    end

end