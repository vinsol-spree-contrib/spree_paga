Spree::Core::Engine.routes.draw do
  # Add your extension routes here
  post :paga_callback, :controller => "checkout", :action => "paga_callback"

  get :confirm_paga_payment, :controller => "checkout", :action => "confirm_paga_payment"

  post :paga_notification, :controller => "checkout", :action => "paga_notification"

  namespace :admin do
    resources :paga_transactions, :only => [:index] do
    	get :complete, :on => :member
    end
  end

end
