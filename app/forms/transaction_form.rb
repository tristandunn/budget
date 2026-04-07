# frozen_string_literal: true

class TransactionForm < BaseForm
  attr_accessor :account, :budget, :frequency, :memo, :payee, :subcategory
  attr_writer   :amount, :date

  # Build a form prepopulated from an existing transaction.
  #
  # @param transaction [Transaction] The transaction to prepopulate from.
  # @return [TransactionForm] The prepopulated form.
  def self.from(transaction:)
    new(
      account:     transaction.account,
      amount:      Money.from_cents(transaction.amount).to_s,
      budget:      transaction.budget,
      date:        transaction.date.to_s,
      frequency:   transaction.frequency,
      memo:        transaction.memo,
      payee:       transaction.payee,
      subcategory: transaction.subcategory
    )
  end

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

  delegate :recurring_scheduled?, to: :transaction

  # Attempt to save the transaction if it's valid.
  #
  # @return [Boolean] Whether the transaction was saved successfully.
  def save
    if valid?
      if recurring_scheduled?
        transaction.save!
      else
        CreateTransaction.call(transaction: transaction)
      end
    end
  end

  # Build a new transaction.
  #
  # @return [Transaction] The built transaction record.
  def transaction
    @transaction ||= Transaction.new(budget: budget, **attributes)
  end

  # Attempt to update the transaction if the form is valid.
  #
  # @param transaction [Transaction] The transaction to update.
  # @return [Boolean] Whether the transaction was updated successfully.
  def update(transaction)
    if valid?
      update_service_class.call(
        attributes:  attributes,
        transaction: transaction
      )
    end
  end

  private

  # Return the form attributes as a hash for creating or updating a transaction.
  #
  # @return [Hash] The transaction attributes.
  def attributes
    {
      account:     account,
      amount:      amount&.cents,
      date:        date,
      frequency:   frequency.presence,
      memo:        memo,
      payee:       payee,
      subcategory: subcategory
    }
  end

  # Return the appropriate service class for updating a transaction.
  #
  # @return [Class] The service class to use for the update.
  def update_service_class
    if recurring_scheduled?
      DirectUpdateTransaction
    else
      UpdateTransaction
    end
  end

  # Validate the transaction, merging transaction errors into the form errors.
  #
  # @return [Boolean] Whether the transaction is valid.
  def valid?(context = nil)
    transaction.valid?(context).tap do
      errors.merge!(transaction.errors)
    end
  end
end
