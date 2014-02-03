class Spree::PagaTransaction < ActiveRecord::Base

  #[TODO_CR] status should not be accessible. Even amount too. It should be equal to order amount.
  attr_accessible :amount, :status
  MINIMUM_AMT = 1
  PENDING      = 'Pending'
  SUCCESSFUL  = 'Successful'
  UNSUCCESSFUL = 'Unsuccessful'

  belongs_to :order
  belongs_to :user

  #[TODO_CR] Presence validation on user is missing
  validates :amount, :numericality => { :greater_than_or_equal_to => MINIMUM_AMT }
  #[TODO_CR] not sure why these validations needed if response_status?
  validates :transaction_id, :order, :presence => true, :if => lambda {|t| t.response_status? }
  validates :transaction_id, :uniqueness => true

  before_validation :assign_values, :on => :create

  #[TODO_CR] Can we write this condition as :unless => :success?
  before_save :check_transaction_status, :unless => lambda {|t| t.success? }

  #[TODO_CR] this can be removed we change PENDING as a default status value
  def assign_values
    self.status = PENDING
  end

  def success?
    status == SUCCESSFUL
  end

  def pending?
    status == PENDING
  end

  def amount_valid?
    amount >= order.remaining_total
  end

  #[TODO_CR] Do we really need transaction in this methods name.
  # I think currency will be sufficient and same can be delegated from order
  def transaction_currency
    order.currency
  end

  private

  #[TODO_CR] self is not needed
  def check_transaction_status
    paga_notification = Spree::PagaNotification.where(:transaction_id => self.transaction_id).first
    if paga_notification && amount_valid?
      self.status = SUCCESSFUL
      self.amount = paga_notification.amount
    end
    true
  end

end
