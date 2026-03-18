# frozen_string_literal: true

class TransactionForm < BaseForm
  attr_accessor :account, :budget, :memo, :payee, :subcategory
  attr_writer   :amount, :date

  # Return the amount as a Money object.
  #
  # @return [Money] The parsed amount.
  def amount
    value = BigDecimal(@amount.to_s, exception: false)

    if value&.nonzero?
      Money.from_amount(value)
    end
  end

  # Return the date, defaulting to today when blank or unparseable.
  #
  # @return [Date] The parsed date.
  def date
    Date.parse(@date.to_s)
  rescue Date::Error
    Date.current
  end

  # Attempt to save the transaction if it's valid.
  #
  # @return [Boolean] Whether the transaction was saved successfully.
  def save
    if valid?
      CreateTransaction.call(transaction: transaction)
    end
  end

  # Build a new transaction.
  #
  # @return [Transaction] The built transaction record.
  def transaction
    @transaction ||= Transaction.new(
      account:     account,
      amount:      amount&.cents,
      budget:      budget,
      date:        date,
      memo:        memo,
      payee:       payee,
      subcategory: subcategory
    )
  end

  private

  # Validate the transaction, merging transaction errors into the form errors.
  #
  # @return [Boolean] Whether the transaction is valid.
  def valid?(context = nil)
    transaction.valid?(context).tap do
      errors.merge!(transaction.errors)
    end
  end
end
