# frozen_string_literal: true

class TransactionForm < BaseForm
  attr_accessor :budget, :category
  attr_writer   :amount

  # Return the amount as a Money object.
  #
  # @return [Money]
  def amount
    if @amount.to_f.positive?
      Money.from_amount(@amount.to_f)
    end
  end

  # Attempt to save the transaction if it's valid.
  #
  # @return [Boolean]
  def save
    if valid?
      CreateTransaction.call(transaction: transaction)
    end
  end

  # Build a new transaction.
  #
  # @return [Transaction]
  def transaction
    @transaction ||= Transaction.new(amount: amount&.cents, budget: budget, category: category)
  end

  private

  # Validate the transaction, merging transaction errors into the form errors.
  #
  # @return [Boolean]
  def valid?(context = nil)
    transaction.valid?(context).tap do
      errors.merge!(transaction.errors)
    end
  end
end
