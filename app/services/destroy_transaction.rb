# frozen_string_literal: true

class DestroyTransaction
  # Initialize the service.
  #
  # @param transaction [Transaction] The transaction to destroy.
  def initialize(transaction:)
    @transaction = transaction
  end

  # Destroy the transaction and reverse the related balances.
  #
  # @param transaction [Transaction] The transaction to destroy.
  # @return [Boolean] Whether the transaction was destroyed successfully.
  def self.call(transaction:)
    new(transaction: transaction).call
  end

  # Destroy the transaction and reverse the related balances.
  #
  # @return [Boolean] Whether the transaction was destroyed successfully.
  def call
    ActiveRecord::Base.transaction do
      reverse_account_balance
      reverse_category_effects
      transaction.destroy!

      true
    end
  end

  private

  attr_reader :transaction

  delegate :account, :amount, :budget, :date, :subcategory, to: :transaction

  # Reverse the account balance change from the transaction.
  #
  # @return [void]
  def reverse_account_balance
    account.increment!(:balance, -amount)
  end

  # Reverse the category effects of the transaction. For inflow transactions,
  # this reverses the available to assign change. For regular transactions,
  # this reverses the snapshot changes.
  #
  # @return [void]
  def reverse_category_effects
    if subcategory.inflow?
      budget.increment!(:available_to_assign, -amount)
    else
      snapshots.each do |snapshot|
        reverse_snapshot(snapshot)
      end
    end
  end

  # Reverse the effect of the transaction on a single snapshot.
  #
  # @param snapshot [CategorySnapshot] The snapshot to reverse.
  # @return [void]
  def reverse_snapshot(snapshot)
    if amount.positive?
      snapshot.increment!(:amount_assigned, -amount)
    else
      snapshot.increment!(:amount_used, amount)
    end
  end

  # Return the category and subcategory snapshots for the transaction month.
  #
  # @return [Array<CategorySnapshot>] The snapshots for the category and subcategory.
  def snapshots
    [subcategory.parent, subcategory].map do |category|
      category.snapshots.for_month(date).first
    end
  end
end
