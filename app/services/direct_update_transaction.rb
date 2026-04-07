# frozen_string_literal: true

class DirectUpdateTransaction
  # Initialize the service.
  #
  # @param attributes [Hash] The new attributes for the transaction.
  # @param transaction [Transaction] The transaction to update.
  def initialize(attributes:, transaction:)
    @attributes  = attributes
    @transaction = transaction
  end

  # Update the transaction without adjusting balances or category effects.
  #
  # @param attributes [Hash] The new attributes for the transaction.
  # @param transaction [Transaction] The transaction to update.
  # @return [Boolean] Whether the transaction was updated successfully.
  def self.call(attributes:, transaction:)
    new(attributes: attributes, transaction: transaction).call
  end

  # Update the transaction without adjusting balances or category effects.
  #
  # @return [Boolean] Whether the transaction was updated successfully.
  def call
    transaction.update!(attributes)

    true
  end

  private

  attr_reader :attributes, :transaction
end
