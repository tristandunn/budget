# frozen_string_literal: true

class CreateTransaction
  # Initialize the service.
  #
  # @param transaction [Transaction] The transaction to create.
  def initialize(transaction:)
    @transaction = transaction
  end

  # Create the transaction, update the account and category snapshots.
  #
  # @param transaction [Transaction] The transaction to create.
  # @return [Boolean]
  def self.call(transaction:)
    new(transaction: transaction).call
  end

  # Create the transaction, update the account and category snapshots.
  #
  # @return [Boolean]
  def call
    ActiveRecord::Base.transaction do
      account.decrement!(:balance, amount) # rubocop:disable Rails/SkipsModelValidations

      snapshots.each do |snapshot|
        snapshot.increment!(:amount_used, amount) # rubocop:disable Rails/SkipsModelValidations
      end

      transaction.save!

      true
    end
  end

  private

  attr_reader :transaction

  delegate :account, :amount, :subcategory, to: :transaction

  # Return the category and subcategory snapshots for the current month.
  #
  # @return [Array<CategorySnapshot>] The snapshots for the category and subcategory.
  def snapshots
    [
      subcategory.parent.snapshots.for_month(Date.current).first,
      subcategory.snapshots.for_month(Date.current).first
    ]
  end
end
