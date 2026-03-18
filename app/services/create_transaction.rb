# frozen_string_literal: true

class CreateTransaction
  # Initialize the service.
  #
  # @param transaction [Transaction] The transaction to create.
  def initialize(transaction:)
    @transaction = transaction
  end

  # Create the transaction and update the related balances.
  #
  # @param transaction [Transaction] The transaction to create.
  # @return [Boolean] Whether the transaction was created successfully.
  def self.call(transaction:)
    new(transaction: transaction).call
  end

  # Create the transaction and update the related balances.
  #
  # @return [Boolean] Whether the transaction was created successfully.
  def call
    ActiveRecord::Base.transaction do
      increment_account

      if subcategory.inflow?
        increment_available_to_assign
      else
        increment_snapshots
      end

      transaction.save!

      true
    end
  end

  private

  attr_reader :transaction

  delegate :account, :amount, :budget, :date, :subcategory, to: :transaction

  # Update the budget available to assign based on the transaction amount.
  #
  # @return [void]
  def increment_available_to_assign
    budget.increment!(:available_to_assign, amount)
  end

  # Update the account based on the transaction amount.
  #
  # @return [void]
  def increment_account
    account.increment!(:balance, amount)
  end

  # Update the category and subcategory snapshots based on transaction amount.
  #
  # @return [void]
  def increment_snapshots
    snapshots.each do |snapshot|
      if amount.positive?
        snapshot.increment!(:amount_assigned, amount)
      else
        snapshot.increment!(:amount_used, amount.abs)
      end
    end
  end

  # Return the category and subcategory snapshots for the transaction month.
  #
  # @return [Array<CategorySnapshot>] The snapshots for the category and subcategory.
  def snapshots
    [
      subcategory.parent.snapshots.for_month(date).first,
      subcategory.snapshots.for_month(date).first
    ]
  end
end
