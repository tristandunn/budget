# frozen_string_literal: true

class UpdateTransaction
  # Initialize the service.
  #
  # @param attributes [Hash] The new attributes for the transaction.
  # @param transaction [Transaction] The transaction to update.
  def initialize(attributes:, transaction:)
    @attributes           = attributes
    @previous_transaction = transaction.dup
    @transaction          = transaction
  end

  # Update the transaction and adjust the related balances.
  #
  # @param attributes [Hash] The new attributes for the transaction.
  # @param transaction [Transaction] The transaction to update.
  # @return [Boolean] Whether the transaction was updated successfully.
  def self.call(attributes:, transaction:)
    new(attributes: attributes, transaction: transaction).call
  end

  # Update the transaction and adjust the related balances.
  #
  # @return [Boolean] Whether the transaction was updated successfully.
  def call
    ActiveRecord::Base.transaction do
      transaction.update!(attributes)
      adjust_account_balance
      adjust_category_effects

      true
    end
  end

  private

  attr_reader :attributes, :previous_transaction, :transaction

  delegate :account, :amount, :budget, :date, :subcategory, to: :transaction
  delegate :account, :amount, :date, :subcategory, to: :previous_transaction, prefix: :previous

  # Adjust the account balance based on what changed.
  #
  # @return [void]
  def adjust_account_balance
    if account == previous_account
      if amount_delta.nonzero?
        account.increment!(:balance, amount_delta)
      end
    else
      previous_account.increment!(:balance, -previous_amount)
      account.increment!(:balance, amount)
    end
  end

  # Adjust the category effects based on what changed.
  #
  # @return [void]
  def adjust_category_effects
    if delta_optimizable?
      adjust_snapshot_deltas
    else
      apply_category_effect(previous_subcategory, previous_date, previous_amount, multiplier: -1)
      apply_category_effect(subcategory, date, amount)
    end
  end

  # Adjust a single snapshot by the per-column deltas.
  #
  # @param snapshot [CategorySnapshot] The snapshot to adjust.
  # @return [void]
  def adjust_snapshot_delta(snapshot)
    if assigned_delta.nonzero?
      snapshot.increment!(:amount_assigned, assigned_delta)
    end

    if used_delta.nonzero?
      snapshot.increment!(:amount_used, used_delta)
    end
  end

  # Adjust snapshot deltas when the subcategory and month are unchanged.
  #
  # @return [void]
  def adjust_snapshot_deltas
    if amount_delta.nonzero?
      snapshots_for(subcategory, date).each do |snapshot|
        adjust_snapshot_delta(snapshot)
      end
    end
  end

  # Return the difference between the new and previous amounts.
  #
  # @return [Integer] The difference between the new and previous amounts.
  def amount_delta
    @amount_delta ||= amount - previous_amount
  end

  # Apply or reverse a category effect. The multiplier controls direction:
  # +1 applies the effect, -1 reverses it.
  #
  # @param subcategory [Category] The subcategory to apply the effect to.
  # @param date [Date] The date for snapshot lookup.
  # @param amount [Integer] The original transaction amount.
  # @param multiplier [Integer] The direction multiplier (1 or -1).
  # @return [void]
  def apply_category_effect(subcategory, date, amount, multiplier: 1)
    if subcategory.inflow?
      budget.increment!(:available_to_assign, amount * multiplier)
    else
      snapshots_for(subcategory, date).each do |snapshot|
        apply_to_snapshot(snapshot, amount, multiplier: multiplier)
      end
    end
  end

  # Apply an amount to the appropriate snapshot column. The sign of the amount
  # determines the column, the multiplier controls the direction.
  #
  # @param snapshot [CategorySnapshot] The snapshot to adjust.
  # @param amount [Integer] The original transaction amount.
  # @param multiplier [Integer] The direction multiplier (1 or -1).
  # @return [void]
  def apply_to_snapshot(snapshot, amount, multiplier: 1)
    if amount.positive?
      snapshot.increment!(:amount_assigned, amount * multiplier)
    else
      snapshot.increment!(:amount_used, -amount * multiplier)
    end
  end

  # Return the delta for the amount assigned column.
  #
  # @return [Integer] The change in amount assigned.
  def assigned_delta
    @assigned_delta ||= [amount, 0].max - [previous_amount, 0].max
  end

  # Return whether the delta optimization can be used because neither
  # subcategory is inflow and the subcategory and month are unchanged.
  #
  # @return [Boolean] Whether the delta optimization can be used.
  def delta_optimizable?
    [previous_subcategory, subcategory].none?(&:inflow?) && !snapshots_changed?
  end

  # Return whether different snapshots are affected due to a subcategory or
  # month change.
  #
  # @return [Boolean] Whether the snapshots have changed.
  def snapshots_changed?
    previous_subcategory != subcategory ||
      previous_date.beginning_of_month != date.beginning_of_month
  end

  # Return the category and subcategory snapshots for the given subcategory
  # and date.
  #
  # @param subcategory [Category] The subcategory to look up snapshots for.
  # @param date [Date] The date for month-based snapshot lookup.
  # @return [Array<CategorySnapshot>] The parent and subcategory snapshots.
  def snapshots_for(subcategory, date)
    [subcategory.parent, subcategory].map do |category|
      category.snapshots.for_month(date).first
    end
  end

  # Return the delta for the amount used column.
  #
  # @return [Integer] The change in amount used.
  def used_delta
    @used_delta ||= [amount, 0].min.abs - [previous_amount, 0].min.abs
  end
end
