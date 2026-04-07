# frozen_string_literal: true

class PostRecurringTransaction
  # Initialize the service.
  #
  # @param transaction [Transaction] The recurring transaction to post.
  def initialize(transaction:)
    @transaction = transaction
  end

  # Post the recurring transaction and create the next occurrence.
  #
  # @param transaction [Transaction] The recurring transaction to post.
  # @return [Boolean] Whether the transaction was posted successfully.
  def self.call(transaction:)
    new(transaction: transaction).call
  end

  # Post the recurring transaction and create the next occurrence.
  #
  # @return [Boolean] Whether the transaction was posted successfully.
  def call
    ActiveRecord::Base.transaction do
      create_next_occurrence
      post_transaction

      true
    end
  end

  private

  attr_reader :transaction

  # Create the next recurring occurrence copying attributes from the source.
  #
  # @return [Transaction] The newly created occurrence.
  def create_next_occurrence
    Transaction.create!(
      account:     transaction.account,
      amount:      transaction.amount,
      budget:      transaction.budget,
      category_id: transaction.category_id,
      date:        transaction.next_recurring_date,
      frequency:   transaction.frequency,
      memo:        transaction.memo,
      payee:       transaction.payee
    )
  end

  # Clear the frequency and delegate to CreateTransaction for balance effects.
  #
  # @return [Boolean] Whether the transaction was posted successfully.
  def post_transaction
    transaction.frequency = nil

    CreateTransaction.call(transaction: transaction)
  end
end
