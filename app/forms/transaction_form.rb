# frozen_string_literal: true

class TransactionForm < BaseForm
  attr_accessor :account, :budget, :frequency, :memo, :payee, :subcategory
  attr_writer   :amount, :date

  validates :subcategory, presence: true
  validate  :validate_transaction

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
      payee:       transaction.payee.name,
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
      if transaction.scheduled?
        transaction.status = :upcoming
        transaction.save!
      elsif transaction.frequency.present?
        PostRecurringTransaction.call(transaction: transaction)
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
      if posting?(transaction)
        post_updated_transaction(transaction)
      else
        update_service_class(transaction).call(
          attributes:  attributes,
          transaction: transaction
        )
      end
    end
  end

  private

  # Return whether the transaction is being activated from an upcoming
  # transaction to a regular transaction. This is true when the existing
  # transaction is upcoming and the form date is not in the future.
  #
  # @param transaction [Transaction] The existing transaction to check.
  # @return [Boolean] Whether the transaction is being activated.
  def activating?(transaction)
    transaction.upcoming? && !self.transaction.scheduled?
  end

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
      payee:       payee_record,
      subcategory: subcategory
    }
  end

  # Return whether the transaction is becoming recurring. This is true when
  # the existing transaction has no frequency and the form specifies one.
  #
  # @param transaction [Transaction] The existing transaction to check.
  # @return [Boolean] Whether the transaction is becoming recurring.
  def becoming_recurring?(transaction)
    transaction.frequency.blank? && frequency.present?
  end

  # Return the service class for converting a transaction to recurring. When
  # the transaction is already upcoming, it is directly updated instead.
  #
  # @param transaction [Transaction] The existing transaction being converted.
  # @return [Class] The service class to use for the conversion.
  def becoming_recurring_service_class(transaction)
    if recurring_scheduled?
      if transaction.upcoming?
        DirectUpdateTransaction
      else
        SuspendTransaction
      end
    else
      ConvertToRecurringTransaction
    end
  end

  # Return the Payee record for the given payee name, creating one if needed.
  #
  # @return [Payee] The found or created payee record.
  # @return [nil] When the payee name is blank.
  def payee_record
    if payee.present?
      Payee.find_or_create_by!(budget: budget, name: payee)
    end
  end

  # Post an updated recurring transaction that is moving from a future date to
  # a non-future date while keeping the frequency. Apply the form attributes
  # first so the next occurrence is seeded from the edited values.
  #
  # @param transaction [Transaction] The existing transaction to post.
  # @return [Boolean] Whether the transaction was posted successfully.
  def post_updated_transaction(transaction)
    ActiveRecord::Base.transaction do
      transaction.update!(attributes)

      PostRecurringTransaction.call(transaction: transaction)
    end
  end

  # Return whether the transaction is being posted from an upcoming recurring
  # transaction to a non-future date while keeping the frequency.
  #
  # @param transaction [Transaction] The existing transaction to check.
  # @return [Boolean] Whether the transaction is being posted.
  def posting?(transaction)
    transaction.upcoming? &&
      transaction.recurring_scheduled? &&
      frequency.present? &&
      !recurring_scheduled?
  end

  # Return the appropriate service class for updating a transaction.
  #
  # @param transaction [Transaction] The existing transaction being updated.
  # @return [Class] The service class to use for the update.
  def update_service_class(transaction)
    if becoming_recurring?(transaction)
      becoming_recurring_service_class(transaction)
    elsif activating?(transaction)
      ActivateTransaction
    elsif transaction.upcoming?
      DirectUpdateTransaction
    else
      UpdateTransaction
    end
  end

  # Validate the transaction, merging transaction errors into the form errors.
  #
  # @return [void]
  def validate_transaction
    unless transaction.valid?
      errors.merge!(transaction.errors)
    end
  end
end
