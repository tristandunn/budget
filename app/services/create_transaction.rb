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
      increment_account
      increment_snapshots

      transaction.save!

      true
    end
  end

  private

  attr_reader :transaction

  delegate :account, :amount, :subcategory, to: :transaction

  # Update the account based on the transaction amount.
  #
  # @return [void]
  def increment_account
    account.increment!(:balance, amount) # rubocop:disable Rails/SkipsModelValidations
  end

  # Update the category and subcategory snapshots based on transaction amount.
  #
  # @return [void]
  def increment_snapshots
    snapshots.each do |snapshot|
      if amount.positive?
        snapshot.increment!(:amount_assigned, amount) # rubocop:disable Rails/SkipsModelValidations
      else
        snapshot.increment!(:amount_used, amount.abs) # rubocop:disable Rails/SkipsModelValidations
      end
    end
  end

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
