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
      if transaction.transfer?
        destroy_transfer
      else
        destroy_non_transfer
      end

      true
    end
  end

  private

  attr_reader :transaction

  delegate :account, :amount, :budget, :date, :subcategory, to: :transaction

  # Destroy a non-transfer transaction, reversing the account balance and any
  # category effects.
  #
  # Orphaned transfer halves (whose partners have been deleted, nullifying
  # `transfer_pair_id` via the foreign key) also flow through this path. Those
  # rows have no subcategory, because transfers are created without one, so
  # the category reversal is guarded.
  #
  # @return [void]
  def destroy_non_transfer
    unless transaction.upcoming?
      reverse_account_balance(transaction)

      if subcategory
        reverse_category_effects
      end
    end

    transaction.destroy!
  end

  # Destroy a transfer, reversing both account balances and removing the
  # partner row. Transfers are always created as pending, so no upcoming
  # guard is needed. While `transfer_pair_id` is set, the foreign key
  # (`on_delete: :nullify`) ensures the partner row exists.
  #
  # @return [void]
  def destroy_transfer
    pair = transaction.transfer_pair

    reverse_account_balance(transaction)
    reverse_account_balance(pair)

    pair.destroy!
    transaction.destroy!
  end

  # Reverse the account balance change from a transaction.
  #
  # @param record [Transaction] The transaction whose balance change to reverse.
  # @return [void]
  def reverse_account_balance(record)
    record.account.increment!(:balance, -record.amount)
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
