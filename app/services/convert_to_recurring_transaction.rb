# frozen_string_literal: true

class ConvertToRecurringTransaction
  # Initialize the service.
  #
  # @param attributes [Hash] The new attributes for the transaction.
  # @param transaction [Transaction] The transaction to convert.
  def initialize(attributes:, transaction:)
    @attributes  = attributes
    @transaction = transaction
  end

  # Update the transaction without a frequency, then create the next scheduled
  # occurrence advanced by the new frequency from the attributes.
  #
  # @param attributes [Hash] The new attributes for the transaction.
  # @param transaction [Transaction] The transaction to convert.
  # @return [Boolean] Whether the conversion was successful.
  def self.call(attributes:, transaction:)
    new(attributes: attributes, transaction: transaction).call
  end

  # Update the transaction without a frequency, then create the next scheduled
  # occurrence advanced by the new frequency from the attributes.
  #
  # @return [Boolean] Whether the conversion was successful.
  def call
    ActiveRecord::Base.transaction do
      update_transaction
      create_next_occurrence

      true
    end
  end

  private

  attr_reader :attributes, :transaction

  # Create the next scheduled occurrence of the recurring transaction.
  #
  # @return [Transaction] The newly created recurring transaction.
  def create_next_occurrence
    Transaction.create!(
      **transaction.copyable_attributes,
      date:      transaction.next_recurring_date(frequency: attributes[:frequency]),
      frequency: attributes[:frequency],
      status:    :upcoming
    )
  end

  # Update the transaction with the new attributes, keeping frequency nil so
  # the posted transaction stays out of recurring processing.
  #
  # @return [Boolean] Whether the transaction was updated successfully.
  def update_transaction
    UpdateTransaction.call(
      attributes:  attributes.merge(frequency: nil),
      transaction: transaction
    )
  end
end
